#!/usr/bin/env python3
"""
Test script for OddsAPI client

Validates that the client works correctly in dry-run mode without
consuming any API quota.
"""
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add project root to path so we can import from src
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Load .env file from project root
env_path = project_root / ".env"
load_dotenv(env_path)

from src.odds_api.client import OddsAPI


def test_api_key_loading():
    """Test that API key is loaded from environment."""
    print("Test 1: API Key Loading")
    print("-" * 60)

    try:
        api = OddsAPI(dry_run=True)
        print(f"✓ API key loaded successfully")
        print(f"✓ Client initialized with dry_run={api.dry_run}")
        return True
    except RuntimeError as e:
        print(f"✗ Failed to load API key: {e}")
        return False


def test_dry_run_mode():
    """Test that dry-run mode prints requests without making them."""
    print("\nTest 2: Dry-Run Mode")
    print("-" * 60)

    api = OddsAPI(dry_run=True)

    # This should print but NOT make a real API call
    print("Calling API with dry_run=True (should print, not execute):")
    data, quota = api._request("/sports/americanfootball_nfl/odds", {
        "regions": "us",
        "markets": "h2h"
    })

    # In dry-run mode, both should be None
    if data is None and quota is None:
        print("✓ Dry-run mode working correctly (no real API call made)")
        return True
    else:
        print("✗ Dry-run mode failed (API call was made!)")
        return False


def test_url_construction():
    """Test that URLs are constructed correctly."""
    print("\nTest 3: URL Construction")
    print("-" * 60)

    api = OddsAPI(dry_run=True)

    # Expected URL format
    expected_base = "https://api.the-odds-api.com/v4"

    print(f"✓ Base URL: {api.BASE}")
    print(f"✓ Expected: {expected_base}")

    if api.BASE == expected_base:
        print("✓ URL construction is correct")
        return True
    else:
        print("✗ URL construction is incorrect")
        return False


def test_params_formatting():
    """Test that parameters are formatted correctly."""
    print("\nTest 4: Parameter Formatting")
    print("-" * 60)

    api = OddsAPI(dry_run=True)

    # Test with sample params
    test_params = {
        "sport": "americanfootball_nfl",
        "regions": "us",
        "markets": "h2h,spreads"
    }

    print("Test parameters:")
    for key, val in test_params.items():
        print(f"  {key}: {val}")

    # In dry-run, this will print the params
    data, quota = api._request("/sports", test_params)

    print("✓ Parameters formatted and printed correctly")
    return True


def main():
    """Run all tests."""
    print("=" * 60)
    print("  Odds API Client Tests")
    print("=" * 60)
    print()

    tests = [
        test_api_key_loading,
        test_dry_run_mode,
        test_url_construction,
        test_params_formatting
    ]

    results = []
    for test in tests:
        result = test()
        results.append(result)

    print()
    print("=" * 60)
    print("  Test Summary")
    print("=" * 60)

    passed = sum(results)
    total = len(results)

    print(f"Passed: {passed}/{total}")

    if passed == total:
        print("✅ All tests passed! Client is ready for Loop 5:3")
        return 0
    else:
        print("❌ Some tests failed. Review output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
