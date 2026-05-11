from fastapi import HTTPException


def validate_persisted_image_url(value: str | None, *, field_name: str = "image_url") -> str | None:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    lowered = normalized.lower()
    if (
        lowered.startswith("assets/")
        or lowered.startswith("/mock/")
        or lowered.startswith("mock/")
        or lowered.startswith("local://")
    ):
        raise HTTPException(status_code=400, detail=f"{field_name} must be uploaded image url")
    if not (lowered.startswith("http://") or lowered.startswith("https://")):
        raise HTTPException(status_code=400, detail=f"{field_name} must be uploaded image url")
    return normalized
