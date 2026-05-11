from __future__ import annotations

from datetime import datetime
from pathlib import Path
import os
import sys
from typing import Any

import requests


sys.path.append(str(Path(__file__).resolve().parents[1]))

from backend.app.core.database import SessionLocal
from backend.app.core.status import (
    OrderItemStatus,
    OrderStatus,
    PaymentStatus,
    ProcurementStatus,
    ReturnStatus,
    ShipmentStatus,
)
from backend.app.models import (
    Order,
    Procurement,
    Reservation,
    ReturnRequest,
)
from scripts.seed_owner3_workflows import (
    SCENARIOS,
    create_scenario,
)


BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:8000/api/v1").rstrip("/")
OWNER_EMAIL = os.getenv("OWNER_EMAIL", "cheng80@gmail.com")
OWNER_PASSWORD = os.getenv("OWNER_PASSWORD", "pass1234!")
SMOKE_KEY = "SMOKE_API"


def _request(
    session: requests.Session,
    method: str,
    path: str,
    *,
    token: str | None = None,
    json_body: dict[str, Any] | None = None,
) -> dict[str, Any]:
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if json_body is not None:
        headers["Content-Type"] = "application/json"

    response = session.request(
        method,
        f"{BASE_URL}{path}",
        headers=headers,
        json=json_body,
        timeout=15,
    )
    payload = response.json()
    if not response.ok:
        raise RuntimeError(f"{method} {path} failed: {response.status_code} {payload}")
    return payload["data"]


def _cleanup_smoke_data() -> None:
    order_no = f"ORD-OWNER3-{SMOKE_KEY}"
    reservation_no = f"RSV-OWNER3-{SMOKE_KEY}"
    with SessionLocal() as db:
        order = db.query(Order).filter(Order.order_no == order_no).one_or_none()
        reservation = (
            db.query(Reservation)
            .filter(Reservation.reservation_no == reservation_no)
            .one_or_none()
        )
        if order:
            if order.shipment:
                db.delete(order.shipment)
            if order.return_request:
                if order.return_request.refund:
                    db.delete(order.return_request.refund)
                db.delete(order.return_request)
            for payment in list(order.payments):
                db.delete(payment)
            if order.procurement:
                for item in list(order.procurement.procurement_items):
                    for inspection in list(item.quality_inspections):
                        db.delete(inspection)
                    db.delete(item)
                db.delete(order.procurement)
            for item in list(order.order_items):
                db.delete(item)
            db.delete(order)
        if reservation:
            for item in list(reservation.reservation_items):
                if item.slot:
                    item.slot.reserved_kg = max(
                        0,
                        float(item.slot.reserved_kg) - float(item.reserved_kg),
                    )
                db.delete(item)
            db.delete(reservation)
        db.commit()


def _create_smoke_procurement() -> tuple[int, int, int, int]:
    scenario = {
        **SCENARIOS[0],
        "key": SMOKE_KEY,
        "customer": ("owner3_customer_smoke@example.com", "오너스모크 고객"),
        "slot_id": 40,
        "packages": 1,
        "kg": 5,
        "unit_price": 39000,
        "order_status": OrderStatus.PROCUREMENT_REQUESTED,
        "procurement_status": ProcurementStatus.REQUESTED,
        "payment_status": PaymentStatus.APPROVED,
    }
    with SessionLocal() as db:
        _cleanup_smoke_data()
        create_scenario(db, scenario, 90)
        db.commit()
        procurement = (
            db.query(Procurement)
            .filter(Procurement.procurement_no == f"PRC-OWNER3-{SMOKE_KEY}")
            .one()
        )
        item = procurement.procurement_items[0]
        order = procurement.order
        payment = order.payments[0]
        return (
            procurement.procurement_id,
            item.procurement_item_id,
            order.order_id,
            payment.payment_id,
        )


def _add_return_request(order_id: int) -> int:
    with SessionLocal() as db:
        order = db.get(Order, order_id)
        if not order:
            raise RuntimeError("smoke order missing")
        if order.return_request:
            return order.return_request.return_request_id
        return_request = ReturnRequest(
            order_id=order.order_id,
            return_no=f"RET-OWNER3-{SMOKE_KEY}",
            return_status=ReturnStatus.REQUESTED,
            reason_code="QUALITY_ISSUE",
            reason_detail="배송 후 품질 확인 요청",
            evidence_image_url="https://cheng80.myqnapcloud.com/images/owner_demo/product_3_demo_damaged_return_box.png",
            requested_amount=order.total_amount,
            approved_amount=0,
            requested_at=datetime.utcnow(),
        )
        order.order_status = OrderStatus.RETURN_REQUESTED
        for item in order.order_items:
            item.order_item_status = OrderItemStatus.RETURN_REQUESTED
        db.add(return_request)
        db.commit()
        db.refresh(return_request)
        return return_request.return_request_id


def main() -> int:
    try:
        procurement_id, procurement_item_id, order_id, _payment_id = (
            _create_smoke_procurement()
        )
        session = requests.Session()
        token = _request(
            session,
            "POST",
            "/auth/login",
            json_body={"email": OWNER_EMAIL, "password": OWNER_PASSWORD},
        )["access_token"]

        procurement = _request(
            session,
            "PATCH",
            f"/owner/procurements/{procurement_id}/decision",
            token=token,
            json_body={
                "decision": "APPROVED",
                "items": [
                    {
                        "procurement_item_id": procurement_item_id,
                        "approved_package_count": 1,
                        "approved_kg": 5,
                        "owner_memo": "스모크 검증 승인",
                    }
                ],
                "rejected_reason": None,
            },
        )
        assert procurement["procurement_status"] == ProcurementStatus.APPROVED

        quality = _request(
            session,
            "POST",
            "/owner/quality-inspections",
            token=token,
            json_body={
                "procurement_item_id": procurement_item_id,
                "image_url": "https://cheng80.myqnapcloud.com/images/owner_demo/product_9_demo_yanggwang_product.png",
                "owner_confirmed_grade": "A",
                "owner_decision": "PASS",
            },
        )
        assert quality["owner_decision"] == "PASS"

        shipment = _request(
            session,
            "POST",
            "/owner/shipments",
            token=token,
            json_body={
                "order_id": order_id,
                "carrier_name": "CJ대한통운",
                "tracking_no": "777700001234",
                "shipped_package_count": 1,
                "shipped_kg": 5,
            },
        )
        shipment_id = shipment["shipment_id"]
        assert shipment["shipment_status"] == ShipmentStatus.SHIPPED

        delivered = _request(
            session,
            "PATCH",
            f"/owner/shipments/{shipment_id}/status",
            token=token,
            json_body={"shipment_status": "DELIVERED"},
        )
        assert delivered["shipment_status"] == ShipmentStatus.DELIVERED

        return_request_id = _add_return_request(order_id)
        decided_return = _request(
            session,
            "PATCH",
            f"/owner/returns/{return_request_id}/decision",
            token=token,
            json_body={
                "decision": "APPROVED",
                "approved_amount": 39000,
                "decision_reason": "스모크 검증 환불 승인",
            },
        )
        assert decided_return["return_status"] == ReturnStatus.REFUNDED
        assert decided_return["refund_status"] == "COMPLETED"
    finally:
        _cleanup_smoke_data()

    print("owner workflow smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
