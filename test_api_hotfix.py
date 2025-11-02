#!/usr/bin/env python3
"""
Quick test to verify /api/analyze endpoint doesn't crash with missing user_id.
Tests the dependency injection fix.
"""

import requests

def test_analyze_endpoint():
    """Test /api/analyze returns 401 for missing token instead of 500 NameError."""

    base_url = "http://localhost:8000"  # or "https://api.websler.pro" for live test

    # Test 1: Missing authorization header should return 401
    print("Test 1: Missing authorization header...")
    response = requests.post(
        f"{base_url}/api/analyze",
        json={"url": "https://example.com"},
        headers={"Content-Type": "application/json"}
    )

    assert response.status_code == 401, f"Expected 401, got {response.status_code}"
    assert "Missing authorization header" in response.text or "Unauthorized" in response.text
    print("✅ Test 1 PASS: Returns 401 for missing token")

    # Test 2: Invalid authorization format should return 401
    print("\nTest 2: Invalid authorization format...")
    response = requests.post(
        f"{base_url}/api/analyze",
        json={"url": "https://example.com"},
        headers={
            "Content-Type": "application/json",
            "Authorization": "InvalidFormat"
        }
    )

    assert response.status_code == 401, f"Expected 401, got {response.status_code}"
    print("✅ Test 2 PASS: Returns 401 for invalid token format")

    # Test 3: Malformed JWT should return 401
    print("\nTest 3: Malformed JWT...")
    response = requests.post(
        f"{base_url}/api/analyze",
        json={"url": "https://example.com"},
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer invalid.jwt.token"
        }
    )

    assert response.status_code == 401, f"Expected 401, got {response.status_code}"
    print("✅ Test 3 PASS: Returns 401 for malformed JWT")

    print("\n✅ ALL TESTS PASSED")
    print("The endpoint now properly returns 401 instead of 500 NameError")


if __name__ == "__main__":
    test_analyze_endpoint()
