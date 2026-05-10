#!/usr/bin/env python3
"""Safely migrate SMART_APP owner-app FastAPI endpoints into SMART_WEB backend.

Default mode is dry-run. Use --apply to write changes.

This script intentionally patches only the endpoint-level additions needed by
the owner app. It does not copy whole files, so SMART_WEB-only address endpoints
and PUT /me remain intact.
"""

from __future__ import annotations

import argparse
import ast
import compileall
import difflib
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


METHODS = {"get", "post", "put", "patch", "delete"}


@dataclass
class Change:
    path: Path
    before: str
    after: str
    description: str

    @property
    def changed(self) -> bool:
        return self.before != self.after


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Migrate SMART_APP owner endpoints into SMART_WEB backend safely.",
    )
    parser.add_argument(
        "--target",
        default="/Users/cheng80/Desktop/smart_web/backend",
        help="SMART_WEB backend directory. Default: /Users/cheng80/Desktop/smart_web/backend",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes. Without this flag the script only prints a dry-run diff.",
    )
    parser.add_argument(
        "--backup-dir",
        default=None,
        help="Backup directory for changed files. Default: <target>/.migration_backups/<timestamp>",
    )
    return parser.parse_args()


def endpoint_set(root: Path) -> set[tuple[str, str]]:
    rows: set[tuple[str, str]] = set()
    for path in sorted((root / "app" / "routers").glob("*_router.py")):
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            for dec in node.decorator_list:
                if not isinstance(dec, ast.Call) or not isinstance(dec.func, ast.Attribute):
                    continue
                method = dec.func.attr.lower()
                if method not in METHODS:
                    continue
                if not isinstance(dec.func.value, ast.Name) or dec.func.value.id != "router":
                    continue
                if not dec.args or not isinstance(dec.args[0], ast.Constant):
                    continue
                rows.add((method.upper(), str(dec.args[0].value)))
    return rows


def require_file(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"required file not found: {path}")
    return path.read_text()


def insert_before(text: str, marker: str, snippet: str) -> str:
    if snippet.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"marker not found: {marker!r}")
    return text.replace(marker, snippet + marker, 1)


def insert_after(text: str, marker: str, snippet: str) -> str:
    if snippet.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"marker not found: {marker!r}")
    return text.replace(marker, marker + snippet, 1)


def replace_once(text: str, old: str, new: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise SystemExit(f"target text not found: {old!r}")
    return text.replace(old, new, 1)


def patch_auth_schema(path: Path) -> Change:
    before = require_file(path)
    after = before
    if "class EmailFindRequest(BaseModel):" not in after:
        after = insert_before(
            after,
            "\nclass TokenResponse(BaseModel):",
            """
class EmailFindRequest(BaseModel):
    name: str
    phone: str
    role: str = Field(default="OWNER", json_schema_extra={"example": "OWNER"})


class PasswordResetRequest(BaseModel):
    name: str
    email: str
    role: str = Field(default="OWNER", json_schema_extra={"example": "OWNER"})


class PasswordResetConfirmRequest(BaseModel):
    email: str
    code: str = Field(min_length=6, max_length=6, json_schema_extra={"example": "123456"})
    new_password: str = Field(min_length=8)
    role: str = Field(default="OWNER", json_schema_extra={"example": "OWNER"})

""",
        )
    return Change(path, before, after, "add auth request schemas")


def patch_auth_router(path: Path) -> Change:
    before = require_file(path)
    after = before
    after = replace_once(
        after,
        "    EmailResendRequest,\n",
        "    EmailResendRequest,\n    EmailFindRequest,\n",
    )
    after = replace_once(
        after,
        "    LoginRequest,\n",
        "    LoginRequest,\n    PasswordResetConfirmRequest,\n    PasswordResetRequest,\n",
    )
    if '@router.post("/auth/email/find")' not in after:
        after = insert_before(
            after,
            "@router.post(\n    \"/auth/login\"",
            """
@router.post("/auth/email/find")
def find_email(payload: EmailFindRequest, db: Session = Depends(get_db)) -> dict:
    return success_response(AuthService(db).find_email(**payload.model_dump()))


@router.post("/auth/password/reset-request")
def request_password_reset(payload: PasswordResetRequest, db: Session = Depends(get_db)) -> dict:
    return success_response(AuthService(db).request_password_reset(**payload.model_dump()))


@router.post("/auth/password/reset-confirm")
def confirm_password_reset(payload: PasswordResetConfirmRequest, db: Session = Depends(get_db)) -> dict:
    return success_response(AuthService(db).confirm_password_reset(**payload.model_dump()))


""",
        )
    return Change(path, before, after, "add auth recovery routes")


def patch_auth_service(path: Path) -> Change:
    before = require_file(path)
    after = before
    if "    def find_email(" not in after:
        after = insert_before(
            after,
            "    def update_me(",
            """
    def find_email(self, *, name: str, phone: str, role: str = AccountRole.OWNER) -> dict:
        normalized_role = role.upper()
        account: Account | None = None
        if normalized_role == AccountRole.OWNER:
            profile = (
                self.session.query(OwnerProfile)
                .join(Account)
                .filter(OwnerProfile.owner_name == name, OwnerProfile.owner_phone == phone)
                .one_or_none()
            )
            account = profile.account if profile else None
        else:
            profile = (
                self.session.query(CustomerProfile)
                .join(Account)
                .filter(CustomerProfile.customer_name == name, CustomerProfile.customer_phone == phone)
                .one_or_none()
            )
            account = profile.account if profile else None
        if not account:
            raise HTTPException(status_code=404, detail="account not found")
        return {
            "email": account.email,
            "masked_email": mask_email(account.email),
            "role": account.role,
        }

    def request_password_reset(self, *, name: str, email: str, role: str = AccountRole.OWNER) -> dict:
        normalized_email = normalize_email(email)
        normalized_role = role.upper()
        account = self.repo.get_by_email(normalized_email)
        if not account or account.role != normalized_role:
            raise HTTPException(status_code=404, detail="account not found")
        if normalized_role == AccountRole.OWNER:
            profile = account.owner_profile
            if not profile or profile.owner_name != name:
                raise HTTPException(status_code=404, detail="account not found")
        else:
            profile = account.customer_profile
            if not profile or profile.customer_name != name:
                raise HTTPException(status_code=404, detail="account not found")

        verification = self.email_verification_service.send_verification(
            email=normalized_email,
            purpose="RESET_PASSWORD",
        )
        return {
            "email": normalized_email,
            "masked_email": mask_email(normalized_email),
            "resend_available_seconds": verification.get("resend_available_seconds"),
            "dev_code": verification.get("dev_code"),
        }

    def confirm_password_reset(
        self,
        *,
        email: str,
        code: str,
        new_password: str,
        role: str = AccountRole.OWNER,
    ) -> dict:
        normalized_email = normalize_email(email)
        normalized_role = role.upper()
        account = self.repo.get_by_email(normalized_email)
        if not account or account.role != normalized_role:
            raise HTTPException(status_code=404, detail="account not found")

        self.email_verification_service.verify_code(
            email=normalized_email,
            code=code,
            purpose="RESET_PASSWORD",
        )
        account.password_hash = hash_password(new_password)
        self.session.commit()
        return {
            "email": normalized_email,
            "password_reset": True,
        }

""",
        )
    if "def mask_email(email: str) -> str:" not in after:
        after += """

def mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    if len(local) <= 2:
        masked_local = f"{local[:1]}***"
    else:
        masked_local = f"{local[:2]}***{local[-1:]}"
    return f"{masked_local}@{domain}" if domain else masked_local
"""
    return Change(path, before, after, "add auth recovery service methods")


def patch_owner_router(path: Path) -> Change:
    before = require_file(path)
    after = before
    if '@router.post("/owner/farms/{farm_id}/image")' not in after:
        after = insert_before(
            after,
            '@router.get("/owner/products")',
            """
@router.post("/owner/farms/{farm_id}/image")
def upload_farm_image(
    farm_id: int,
    file: UploadFile = File(..., description="농장 대표 이미지 파일"),
    current_user: AuthenticatedUser = Depends(require_owner),
    db: Session = Depends(get_db),
) -> dict:
    return success_response(ProductService(db).upload_farm_image(current_user.owner_id, farm_id, file))


""",
        )
    return Change(path, before, after, "add farm image route")


def patch_product_service(path: Path) -> Change:
    before = require_file(path)
    after = before
    after = replace_once(
        after,
        '"open_slot_count": open_slot_count if open_slot_count is not None else 0,',
        '"open_slot_count": open_slot_count if open_slot_count is not None else len(open_slots),',
    )
    if "    def upload_farm_image(" not in after:
        after += """

    def upload_farm_image(self, owner_id: int, farm_id: int, upload: UploadFile) -> dict:
        farm = self.farm_repo.get(farm_id)
        if not farm or farm.owner_id != owner_id:
            raise HTTPException(status_code=404, detail="farm not found")

        upload_result = self.image_storage_service.upload_image(
            upload,
            product_seq=farm.farm_id,
            subfolder=f"farms/{farm.owner_id}",
        )
        farm.farm_image_url = upload_result["file_url"]
        self.session.commit()
        self.session.refresh(farm)

        data = serialize_farm(farm)
        data["file_name"] = upload_result["file_name"]
        data["subfolder"] = upload_result["subfolder"]
        return data
"""
    return Change(path, before, after, "add farm image service")


def patch_shipment_router(path: Path) -> Change:
    before = require_file(path)
    after = before
    if '@router.get("/owner/shipments")' not in after:
        after = insert_before(
            after,
            '@router.patch("/owner/shipments/{shipment_id}/status")',
            """
@router.get("/owner/shipments")
def list_owner_shipments(
    current_user: AuthenticatedUser = Depends(require_owner),
    db: Session = Depends(get_db),
) -> dict:
    return success_response(ShipmentService(db).list_owner_shipments(current_user.owner_id))


""",
        )
    return Change(path, before, after, "add owner shipment list route")


def patch_shipment_service(path: Path) -> Change:
    before = require_file(path)
    after = before
    if "    def list_owner_shipments(" not in after:
        after = insert_before(
            after,
            "    def get_my_shipment(",
            """
    def list_owner_shipments(self, owner_id: int) -> list[dict]:
        rows = self.session.query(Shipment).order_by(Shipment.created_at.desc()).all()
        filtered = [
            shipment
            for shipment in rows
            if shipment.order and shipment.order.procurement and shipment.order.procurement.owner_id == owner_id
        ]
        return [serialize_owner_shipment(shipment) for shipment in filtered]

""",
        )
    if "def serialize_owner_shipment(shipment: Shipment) -> dict:" not in after:
        after += """

def serialize_owner_shipment(shipment: Shipment) -> dict:
    data = serialize_shipment(shipment)
    order = shipment.order
    first_item = order.order_items[0] if order and order.order_items else None
    reservation_item = first_item.reservation_item if first_item else None
    slot = reservation_item.slot if reservation_item else None
    product = slot.product if slot else None
    customer = order.reservation.customer if order and order.reservation else None
    data.update(
        {
            "order_no": order.order_no if order else None,
            "order_status": order.order_status if order else None,
            "customer_name": customer.customer_name if customer else None,
            "product_name": product.product_name if product else None,
            "package_count": first_item.package_count if first_item else shipment.shipped_package_count,
            "ordered_kg": float(first_item.ordered_kg) if first_item else float(shipment.shipped_kg),
            "total_amount": order.total_amount if order else None,
            "ordered_at": order.ordered_at if order else None,
        }
    )
    return data
"""
    return Change(path, before, after, "add owner shipment list service")


def collect_changes(target: Path) -> list[Change]:
    app = target / "app"
    if not app.exists():
        raise SystemExit(f"target does not look like backend root: {target}")
    return [
        patch_auth_schema(app / "schemas" / "auth_schema.py"),
        patch_auth_router(app / "routers" / "auth_router.py"),
        patch_auth_service(app / "services" / "auth_service.py"),
        patch_owner_router(app / "routers" / "owner_router.py"),
        patch_product_service(app / "services" / "product_service.py"),
        patch_shipment_router(app / "routers" / "shipment_router.py"),
        patch_shipment_service(app / "services" / "shipment_service.py"),
    ]


def print_diffs(changes: list[Change]) -> None:
    for change in changes:
        if not change.changed:
            print(f"UNCHANGED {change.path} ({change.description})")
            continue
        print(f"CHANGED {change.path} ({change.description})")
        diff = difflib.unified_diff(
            change.before.splitlines(keepends=True),
            change.after.splitlines(keepends=True),
            fromfile=str(change.path) + " before",
            tofile=str(change.path) + " after",
        )
        print("".join(diff))


def backup_and_write(changes: list[Change], target: Path, backup_dir: Path) -> None:
    backup_dir.mkdir(parents=True, exist_ok=True)
    for change in changes:
        if not change.changed:
            continue
        relative = change.path.relative_to(target)
        backup_path = backup_dir / relative
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(change.path, backup_path)
        change.path.write_text(change.after)
        print(f"WROTE {change.path}")
        print(f"BACKUP {backup_path}")


def main() -> int:
    args = parse_args()
    target = Path(args.target).resolve()
    backup_dir = (
        Path(args.backup_dir).resolve()
        if args.backup_dir
        else target / ".migration_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
    )

    before_endpoints = endpoint_set(target)
    changes = collect_changes(target)
    changed = [change for change in changes if change.changed]
    print(f"target={target}")
    print(f"mode={'apply' if args.apply else 'dry-run'}")
    print(f"changed_files={len(changed)}")
    print_diffs(changes)

    if not args.apply:
        print("dry-run complete. Re-run with --apply to write changes.")
        return 0

    backup_and_write(changes, target, backup_dir)
    after_endpoints = endpoint_set(target)
    expected = {
        ("POST", "/auth/email/find"),
        ("POST", "/auth/password/reset-request"),
        ("POST", "/auth/password/reset-confirm"),
        ("POST", "/owner/farms/{farm_id}/image"),
        ("GET", "/owner/shipments"),
    }
    missing = sorted(expected - after_endpoints)
    if missing:
        raise SystemExit(f"migration wrote files but endpoints are still missing: {missing}")

    preserved = {
        ("GET", "/me/addresses"),
        ("POST", "/me/addresses"),
        ("PUT", "/me/addresses/{address_id}"),
        ("PATCH", "/me/addresses/{address_id}/default"),
        ("DELETE", "/me/addresses/{address_id}"),
        ("PUT", "/me"),
    }
    lost = sorted((preserved & before_endpoints) - after_endpoints)
    if lost:
        raise SystemExit(f"migration removed SMART_WEB endpoints unexpectedly: {lost}")

    print("running compileall...")
    ok = compileall.compile_dir(str(target), quiet=1)
    if not ok:
        raise SystemExit("compileall failed")
    print("migration complete")
    print(f"backup_dir={backup_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
