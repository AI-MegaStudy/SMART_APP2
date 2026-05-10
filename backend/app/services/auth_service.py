from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.config import settings
from backend.app.core.security import create_access_token, hash_password, verify_password
from backend.app.core.status import AccountRole, AccountStatus
from backend.app.models.account import Account, CustomerProfile, OwnerProfile
from backend.app.repositories.account_repo import AccountRepository
from backend.app.services.email_verification_service import EmailVerificationService, normalize_email


class AuthService:
    def __init__(self, session: Session):
        self.session = session
        self.repo = AccountRepository(session)
        self.email_verification_service = EmailVerificationService(session)

    def signup_customer(self, email: str, password: str, name: str, phone: str) -> dict:
        normalized_email = normalize_email(email)
        self.email_verification_service.validate_email_format(normalized_email)
        self.email_verification_service.ensure_verified_for_signup(normalized_email)

        if self.repo.get_by_email(normalized_email):
            raise HTTPException(status_code=400, detail="email already exists")

        account = Account(
            email=normalized_email,
            password_hash=hash_password(password),
            role=AccountRole.CUSTOMER,
            status=AccountStatus.ACTIVE,
            email_verified=self.email_verification_service.get_status(normalized_email, "SIGNUP")["verified"],
        )
        self.session.add(account)
        self.session.flush()

        profile = CustomerProfile(
            account_id=account.account_id,
            customer_name=name,
            customer_phone=phone,
        )
        self.session.add(profile)
        self.session.commit()

        return {
            "account_id": account.account_id,
            "customer_id": profile.customer_id,
            "email": account.email,
            "email_verified": account.email_verified,
            "email_verification_required": settings.email_verification_required,
        }

    def signup_owner(self, email: str, password: str, name: str, phone: str) -> dict:
        normalized_email = normalize_email(email)
        self.email_verification_service.validate_email_format(normalized_email)
        self.email_verification_service.ensure_verified_for_signup(normalized_email)

        if self.repo.get_by_email(normalized_email):
            raise HTTPException(status_code=400, detail="email already exists")

        account = Account(
            email=normalized_email,
            password_hash=hash_password(password),
            role=AccountRole.OWNER,
            status=AccountStatus.ACTIVE,
            email_verified=self.email_verification_service.get_status(normalized_email, "SIGNUP")["verified"],
        )
        self.session.add(account)
        self.session.flush()

        profile = OwnerProfile(
            account_id=account.account_id,
            owner_name=name,
            owner_phone=phone,
        )
        self.session.add(profile)
        self.session.commit()

        return {
            "account_id": account.account_id,
            "owner_id": profile.owner_id,
            "email": account.email,
            "email_verified": account.email_verified,
            "email_verification_required": settings.email_verification_required,
        }

    def login(self, email: str, password: str) -> dict:
        normalized_email = normalize_email(email)
        account = self.repo.get_by_email(normalized_email)
        if not account or not verify_password(password, account.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid email or password")
        account.last_login_at = datetime.utcnow()
        self.session.commit()
        access_token = create_access_token(subject=account.email, role=account.role)
        return {"access_token": access_token, "token_type": "bearer", "role": account.role}

    def get_me(self, account_id: int) -> dict:
        account = self.repo.get_account(account_id)
        if not account:
            raise HTTPException(status_code=404, detail="account not found")
        customer_profile = None
        owner_profile = None
        if account.customer_profile:
            customer_profile = {
                "customer_id": account.customer_profile.customer_id,
                "customer_name": account.customer_profile.customer_name,
                "customer_phone": account.customer_profile.customer_phone,
                "default_receiver_name": account.customer_profile.default_receiver_name,
                "default_receiver_phone": account.customer_profile.default_receiver_phone,
                "default_shipping_address": account.customer_profile.default_shipping_address,
            }
        if account.owner_profile:
            owner_profile = {
                "owner_id": account.owner_profile.owner_id,
                "owner_name": account.owner_profile.owner_name,
                "owner_phone": account.owner_profile.owner_phone,
                "business_number": account.owner_profile.business_number,
            }
        return {
            "account_id": account.account_id,
            "email": account.email,
            "role": account.role,
            "status": account.status,
            "email_verified": account.email_verified,
            "customer_profile": customer_profile,
            "owner_profile": owner_profile,
        }

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


def mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    if len(local) <= 2:
        masked_local = f"{local[:1]}***"
    else:
        masked_local = f"{local[:2]}***{local[-1:]}"
    return f"{masked_local}@{domain}" if domain else masked_local
