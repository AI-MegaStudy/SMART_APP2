"""
FastAPI 점주 API 응답 JSON 확인용 스크립트

PowerShell 실행 예:
$env:BASE_URL="http://127.0.0.1:8000/api/v1"
$env:OWNER_EMAIL="owner@test.com"
$env:OWNER_PASSWORD="demo1234!"
$env:PROCUREMENT_ITEM_ID="1"
python scripts/owner_api_check.py
"""

import json
import os
import sys
from typing import Any

import requests


BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:8000/api/v1").rstrip("/")
OWNER_EMAIL = os.getenv("OWNER_EMAIL", "owner@test.com")
OWNER_PASSWORD = os.getenv("OWNER_PASSWORD", "demo1234!")
PROCUREMENT_ITEM_ID = int(os.getenv("PROCUREMENT_ITEM_ID", "1"))


def print_section(title: str) -> None:
    print(f"\n{'=' * 80}")
    print(title)
    print(f"{'=' * 80}")


def pretty_print_json(data: Any) -> None:
    try:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except (TypeError, ValueError):
        print(data)


def print_response(step: str, method: str, path: str, response: requests.Response) -> Any:
    print_section(f"{step}: {method} {path}")
    print(f"Status Code: {response.status_code}")

    try:
        payload = response.json()
    except ValueError:
        print("Response Body: <non-JSON response>")
        print(response.text)
        return None

    print("Response JSON:")
    pretty_print_json(payload)
    return payload


def request_json(
    session: requests.Session,
    step: str,
    method: str,
    path: str,
    *,
    headers: dict[str, str] | None = None,
    json_body: dict[str, Any] | None = None,
) -> tuple[requests.Response | None, Any]:
    url = f"{BASE_URL}{path}"

    try:
        response = session.request(
            method=method,
            url=url,
            headers=headers,
            json=json_body,
            timeout=15,
        )
    except requests.RequestException as error:
        print_section(f"{step}: {method} {path}")
        print(f"Request failed: {error}")
        return None, None

    payload = print_response(step, method, path, response)
    return response, payload


def main() -> int:
    session = requests.Session()
    default_headers = {"Accept": "application/json"}

    print_section("Owner API Check Configuration")
    print(f"BASE_URL: {BASE_URL}")
    print(f"OWNER_EMAIL: {OWNER_EMAIL}")
    print(f"PROCUREMENT_ITEM_ID: {PROCUREMENT_ITEM_ID}")

    login_response, login_payload = request_json(
        session,
        "STEP 1",
        "POST",
        "/auth/login",
        headers={**default_headers, "Content-Type": "application/json"},
        json_body={
            "email": OWNER_EMAIL,
            "password": OWNER_PASSWORD,
        },
    )
    if login_response is None:
        print("\nStopped at STEP 1: POST /auth/login")
        return 1

    if not login_response.ok:
        print("\nStopped at STEP 1: POST /auth/login")
        return 1

    access_token = None
    if isinstance(login_payload, dict):
        data = login_payload.get("data")
        if isinstance(data, dict):
            token_value = data.get("access_token")
            if isinstance(token_value, str) and token_value:
                access_token = token_value

    if not access_token:
        print("\nStopped at STEP 1: access_token not found in response['data']")
        return 1

    auth_headers = {
        **default_headers,
        "Authorization": f"Bearer {access_token}",
    }

    steps = [
        ("STEP 2", "GET", "/me", None),
        ("STEP 3", "GET", "/owner/dashboard", None),
        ("STEP 4", "GET", "/owner/products", None),
        ("STEP 5", "GET", "/owner/procurements", None),
        (
            "STEP 6",
            "POST",
            "/owner/quality-inspections/analyze",
            {
                "procurement_item_id": PROCUREMENT_ITEM_ID,
                "image_url": "https://example.com/sample.jpg",
                "persist_image": False,
            },
        ),
    ]

    for step, method, path, body in steps:
        headers = auth_headers.copy()
        if body is not None:
            headers["Content-Type"] = "application/json"

        response, _ = request_json(
            session,
            step,
            method,
            path,
            headers=headers,
            json_body=body,
        )

        if response is None:
            print(f"\nStopped at {step}: {method} {path}")
            return 1

        if not response.ok:
            print(f"\nStopped at {step}: {method} {path}")
            return 1

    print_section("Completed")
    print("All requested API calls finished.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
