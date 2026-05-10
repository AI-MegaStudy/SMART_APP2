from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path
import sys


sys.path.append(str(Path(__file__).resolve().parents[1]))

from backend.app.core.database import SessionLocal
from backend.app.core.security import hash_password
from backend.app.core.status import (
    AccountRole,
    AccountStatus,
    OrderItemStatus,
    OrderStatus,
    PaymentStatus,
    ProcurementStatus,
    RefundStatus,
    ReservationStatus,
    ReturnStatus,
    ShipmentStatus,
)
from backend.app.models import (
    Account,
    CustomerProfile,
    HarvestSlot,
    Order,
    OrderItem,
    Payment,
    Procurement,
    ProcurementItem,
    QualityInspection,
    Refund,
    Reservation,
    ReservationItem,
    ReturnRequest,
    Shipment,
)


OWNER_ID = 3
FARM_ID = 3
CUSTOMER_PASSWORD = "pass1234!"
FARM_IMAGE_URL = "assets/images/owner_demo/chungju_apple_farm.png"
PRODUCT_IMAGE_URLS = {
    "양광": "assets/images/owner_demo/yanggwang_apples.png",
    "부사": "assets/images/owner_demo/fuji_apples.png",
}


SCENARIOS = [
    {
        "key": "REQUESTED",
        "customer": ("owner3_customer_requested@example.com", "홍길동"),
        "slot_id": 40,
        "packages": 2,
        "kg": 10,
        "unit_price": 39000,
        "order_status": OrderStatus.PROCUREMENT_REQUESTED,
        "procurement_status": ProcurementStatus.REQUESTED,
        "payment_status": PaymentStatus.APPROVED,
    },
    {
        "key": "APPROVED_READY",
        "customer": ("owner3_customer_ready@example.com", "김민지"),
        "slot_id": 41,
        "packages": 3,
        "kg": 9,
        "unit_price": 32000,
        "order_status": OrderStatus.READY_TO_SHIP,
        "procurement_status": ProcurementStatus.APPROVED,
        "payment_status": PaymentStatus.APPROVED,
        "approved": True,
        "quality": True,
    },
    {
        "key": "PARTIAL_QUALITY",
        "customer": ("owner3_customer_quality@example.com", "박서준"),
        "slot_id": 40,
        "packages": 1,
        "kg": 5,
        "unit_price": 39000,
        "order_status": OrderStatus.QUALITY_CHECKING,
        "procurement_status": ProcurementStatus.PARTIAL_APPROVED,
        "payment_status": PaymentStatus.APPROVED,
        "approved": True,
        "approved_packages": 1,
        "approved_kg": 5,
    },
    {
        "key": "SHIPPED",
        "customer": ("owner3_customer_shipped@example.com", "이수현"),
        "slot_id": 41,
        "packages": 2,
        "kg": 6,
        "unit_price": 32000,
        "order_status": OrderStatus.SHIPPED,
        "procurement_status": ProcurementStatus.APPROVED,
        "payment_status": PaymentStatus.APPROVED,
        "approved": True,
        "quality": True,
        "shipment": ShipmentStatus.SHIPPED,
    },
    {
        "key": "RETURN_REQUESTED",
        "customer": ("owner3_customer_return@example.com", "최지우"),
        "slot_id": 40,
        "packages": 1,
        "kg": 5,
        "unit_price": 39000,
        "order_status": OrderStatus.RETURN_REQUESTED,
        "procurement_status": ProcurementStatus.APPROVED,
        "payment_status": PaymentStatus.APPROVED,
        "approved": True,
        "quality": True,
        "shipment": ShipmentStatus.DELIVERED,
        "return_status": ReturnStatus.REQUESTED,
    },
    {
        "key": "REJECTED",
        "customer": ("owner3_customer_rejected@example.com", "정하윤"),
        "slot_id": 41,
        "packages": 1,
        "kg": 3,
        "unit_price": 32000,
        "order_status": OrderStatus.PROCUREMENT_REJECTED,
        "procurement_status": ProcurementStatus.REJECTED,
        "payment_status": PaymentStatus.APPROVED,
        "rejected_reason": "검증용 재고 부족",
    },
]


def get_or_create_customer(session, email: str, name: str) -> CustomerProfile:
    account = session.query(Account).filter(Account.email == email).one_or_none()
    if account and account.customer_profile:
        return account.customer_profile

    account = account or Account(
        email=email,
        password_hash=hash_password(CUSTOMER_PASSWORD),
        role=AccountRole.CUSTOMER,
        status=AccountStatus.ACTIVE,
        email_verified=True,
    )
    session.add(account)
    session.flush()

    profile = CustomerProfile(
        account_id=account.account_id,
        customer_name=name,
        customer_phone="01012345678",
        default_receiver_name=name,
        default_receiver_phone="01012345678",
        default_shipping_address="서울시 강남구 테헤란로 152",
        marketing_agree=False,
    )
    session.add(profile)
    session.flush()
    return profile


def create_scenario(session, scenario: dict, index: int) -> bool:
    key = scenario["key"]
    order_no = f"ORD-OWNER3-{key}"
    existing = session.query(Order).filter(Order.order_no == order_no).one_or_none()
    if existing:
        sync_existing_scenario(session, existing, scenario, index)
        return False

    now = datetime.utcnow() - timedelta(days=7 - index)
    customer = get_or_create_customer(session, *scenario["customer"])
    slot = session.get(HarvestSlot, scenario["slot_id"])
    if not slot or slot.farm_id != FARM_ID:
        raise RuntimeError(f"slot {scenario['slot_id']} not found for farm {FARM_ID}")

    total_amount = int(scenario["packages"] * scenario["unit_price"])
    reservation = Reservation(
        customer_id=customer.customer_id,
        reservation_no=f"RSV-OWNER3-{key}",
        reservation_status=ReservationStatus.ORDERED,
        reserved_until=now + timedelta(days=1),
        total_reserved_kg=scenario["kg"],
        total_amount=total_amount,
    )
    session.add(reservation)
    session.flush()

    reservation_item = ReservationItem(
        reservation_id=reservation.reservation_id,
        slot_id=slot.slot_id,
        package_count=scenario["packages"],
        reserved_kg=scenario["kg"],
        unit_price_snapshot=scenario["unit_price"],
        subtotal_amount=total_amount,
    )
    session.add(reservation_item)
    session.flush()

    order = Order(
        reservation_id=reservation.reservation_id,
        order_no=order_no,
        order_status=scenario["order_status"],
        total_amount=total_amount,
        receiver_name=customer.customer_name,
        receiver_phone=customer.customer_phone,
        shipping_address=customer.default_shipping_address or "서울시 강남구 테헤란로 152",
        delivery_memo="검증용 주문입니다.",
        ordered_at=now + timedelta(minutes=10),
        paid_at=now + timedelta(minutes=20),
    )
    session.add(order)
    session.flush()

    order_item = OrderItem(
        order_id=order.order_id,
        reservation_item_id=reservation_item.reservation_item_id,
        package_count=scenario["packages"],
        ordered_kg=scenario["kg"],
        unit_price=scenario["unit_price"],
        subtotal_amount=total_amount,
        order_item_status=OrderItemStatus.PROCUREMENT_REQUESTED,
    )
    session.add(order_item)
    session.flush()

    payment = Payment(
        order_id=order.order_id,
        payment_provider="MOCK",
        payment_method="MOCK_CARD",
        payment_status=scenario["payment_status"],
        requested_amount=total_amount,
        approved_amount=total_amount,
        mock_transaction_key=f"TX-OWNER3-{key}",
        idempotency_key=f"payment-owner3-{key}",
        requested_at=now + timedelta(minutes=15),
        approved_at=now + timedelta(minutes=20),
    )
    session.add(payment)
    session.flush()

    procurement_status = scenario["procurement_status"]
    procurement = Procurement(
        order_id=order.order_id,
        farm_id=FARM_ID,
        owner_id=OWNER_ID,
        procurement_no=f"PRC-OWNER3-{key}",
        procurement_status=procurement_status,
        requested_at=now + timedelta(minutes=30),
        response_deadline_at=now + timedelta(days=1),
        decided_at=None if procurement_status == ProcurementStatus.REQUESTED else now + timedelta(hours=2),
        rejected_reason=scenario.get("rejected_reason"),
    )
    session.add(procurement)
    session.flush()

    approved_package_count = scenario.get(
        "approved_packages",
        scenario["packages"] if scenario.get("approved") else 0,
    )
    approved_kg = scenario.get(
        "approved_kg",
        scenario["kg"] if scenario.get("approved") else 0,
    )
    approval_status = procurement_status
    if approval_status == ProcurementStatus.APPROVED:
        order_item.order_item_status = OrderItemStatus.APPROVED
    elif approval_status == ProcurementStatus.PARTIAL_APPROVED:
        order_item.order_item_status = OrderItemStatus.PARTIAL_APPROVED
    elif approval_status == ProcurementStatus.REJECTED:
        order_item.order_item_status = OrderItemStatus.REJECTED

    procurement_item = ProcurementItem(
        procurement_id=procurement.procurement_id,
        order_item_id=order_item.order_item_id,
        requested_package_count=scenario["packages"],
        requested_kg=scenario["kg"],
        approved_package_count=approved_package_count,
        approved_kg=approved_kg,
        approval_status=approval_status,
        owner_memo="owner_id=3 검증용 발주 품목",
    )
    session.add(procurement_item)
    session.flush()

    if scenario.get("quality"):
        order_item.order_item_status = OrderItemStatus.QUALITY_CHECKED
        session.add(
            QualityInspection(
                procurement_item_id=procurement_item.procurement_item_id,
                owner_id=OWNER_ID,
                image_url=PRODUCT_IMAGE_URLS["부사"],
                model_grade="A",
                freshness_score=91,
                color_score=88,
                roundness_score=92,
                bruise_probability=0.08,
                model_decision="PASS",
                owner_confirmed_grade="A",
                owner_decision="PASS",
                model_version="mock-v1",
                inspected_at=now + timedelta(hours=3),
            )
        )

    shipment_status = scenario.get("shipment")
    if shipment_status:
        session.add(
            Shipment(
                order_id=order.order_id,
                carrier_name="CJ대한통운",
                tracking_no=f"6600{index:06d}",
                shipped_package_count=approved_package_count or scenario["packages"],
                shipped_kg=approved_kg or scenario["kg"],
                shipment_status=shipment_status,
                shipped_at=now + timedelta(hours=4),
                delivered_at=now + timedelta(days=1) if shipment_status == ShipmentStatus.DELIVERED else None,
            )
        )
        order_item.order_item_status = (
            OrderItemStatus.DELIVERED if shipment_status == ShipmentStatus.DELIVERED else OrderItemStatus.SHIPPED
        )

    return_status = scenario.get("return_status")
    if return_status:
        return_request = ReturnRequest(
            order_id=order.order_id,
            return_no=f"RET-OWNER3-{key}",
            return_status=return_status,
            reason_code="DAMAGED",
            reason_detail="배송 중 일부 상품이 손상되어 반품을 요청했습니다.",
            evidence_image_url=PRODUCT_IMAGE_URLS["양광"],
            requested_amount=total_amount,
            approved_amount=0,
            decision_reason=None,
            requested_at=now + timedelta(days=2),
            decided_at=None,
        )
        session.add(return_request)
        session.flush()
        session.add(
            Refund(
                return_request_id=return_request.return_request_id,
                payment_id=payment.payment_id,
                refund_status=RefundStatus.REQUESTED,
                requested_amount=total_amount,
                refunded_amount=0,
                requested_at=now + timedelta(days=2),
            )
        )
        order_item.order_item_status = OrderItemStatus.RETURN_REQUESTED

    slot.reserved_kg = float(slot.reserved_kg) + float(scenario["kg"])
    if order.order_status in {OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.RETURN_REQUESTED}:
        slot.sold_kg = float(slot.sold_kg) + float(scenario["kg"])
    return True


def sync_existing_scenario(session, order: Order, scenario: dict, index: int) -> None:
    order.order_status = scenario["order_status"]
    customer_name = scenario["customer"][1]
    if order.reservation and order.reservation.customer:
        customer = order.reservation.customer
        customer.customer_name = customer_name
        customer.default_receiver_name = customer_name
    order.receiver_name = customer_name
    procurement = order.procurement
    if not procurement:
        return

    procurement.procurement_status = scenario["procurement_status"]
    procurement.rejected_reason = scenario.get("rejected_reason")
    approved_package_count = scenario.get(
        "approved_packages",
        scenario["packages"] if scenario.get("approved") else 0,
    )
    approved_kg = scenario.get(
        "approved_kg",
        scenario["kg"] if scenario.get("approved") else 0,
    )

    for item in procurement.procurement_items:
        item.approved_package_count = approved_package_count
        item.approved_kg = approved_kg
        item.approval_status = scenario["procurement_status"]
        if scenario.get("quality") and not item.quality_inspections:
            item.order_item.order_item_status = OrderItemStatus.QUALITY_CHECKED
            session.add(
                QualityInspection(
                    procurement_item_id=item.procurement_item_id,
                    owner_id=OWNER_ID,
                    image_url=PRODUCT_IMAGE_URLS["부사"],
                    model_grade="A",
                    freshness_score=91,
                    color_score=88,
                    roundness_score=92,
                    bruise_probability=0.08,
                    model_decision="PASS",
                    owner_confirmed_grade="A",
                    owner_decision="PASS",
                    model_version="mock-v1",
                    inspected_at=datetime.utcnow() - timedelta(hours=1),
                )
            )

    shipment_status = scenario.get("shipment")
    if order.shipment and shipment_status:
        order.shipment.shipment_status = shipment_status
        order.shipment.delivered_at = (
            order.shipment.delivered_at or datetime.utcnow() - timedelta(days=1)
            if shipment_status == ShipmentStatus.DELIVERED
            else None
        )


def main() -> None:
    created = 0
    with SessionLocal() as session:
        sync_demo_images(session)
        for index, scenario in enumerate(SCENARIOS, start=1):
            if create_scenario(session, scenario, index):
                created += 1
        session.commit()
    print(f"created_scenarios={created}")


def sync_demo_images(session) -> None:
    first_slot = session.get(HarvestSlot, SCENARIOS[0]["slot_id"])
    if first_slot and first_slot.farm:
        first_slot.farm.farm_image_url = FARM_IMAGE_URL
        for product in first_slot.farm.products:
            for variety, image_url in PRODUCT_IMAGE_URLS.items():
                if variety in product.product_name or product.variety == variety:
                    product.image_url = image_url
    for scenario in SCENARIOS:
        slot = session.get(HarvestSlot, scenario["slot_id"])
        if not slot or not slot.product:
            continue
        for variety, image_url in PRODUCT_IMAGE_URLS.items():
            if variety in slot.product.product_name or slot.product.variety == variety:
                slot.product.image_url = image_url


if __name__ == "__main__":
    main()
