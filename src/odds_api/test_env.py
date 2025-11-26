#!/usr/bin/env python3
"""
Test script to verify .env file loading

This script tests that:
1. .env file can be found and loaded
2. ODDS_API_KEY is accessible (without printing the value)
3. Environment is ready for API client

Run: python3 src/odds_api/test_env.py
"""
import os
import sys
from pathlib import Path

def test_env_loading():
    """Test .env file loading without exposing the key."""

    # Try to import python-dotenv
    try:
        from dotenv import load_dotenv
        print("✓ python-dotenv is installed")
    except ImportError:
        print("✗ python-dotenv not installed")
        print("  Install with: pip install python-dotenv")
        print("  Or: pip install -r requirements.txt")
        return False

    # Find .env file (should be in project root)
    project_root = Path(__file__).parent.parent.parent
    env_path = project_root / ".env"

    if not env_path.exists():
        print(f"✗ .env file not found at: {env_path}")
        print("  Create it with: touch .env")
        print("  Then add: ODDS_API_KEY=your_key_here")
        return False

    print(f"✓ .env file found at: {env_path}")

    # Load .env file
    load_dotenv(env_path)

    # Check if API key is set (without printing it!)
    api_key = os.getenv("ODDS_API_KEY")

    if not api_key:
        print("✗ ODDS_API_KEY not set in .env")
        print("  Edit .env and replace YOUR_API_KEY_HERE with your actual key")
        return False

    if api_key == "YOUR_API_KEY_HERE":
        print("⚠ ODDS_API_KEY is still the placeholder value")
        print("  Edit .env and replace YOUR_API_KEY_HERE with your actual key")
        print("  Get your key from: https://the-odds-api.com/")
        return False

    # Key is set and not the placeholder
    key_length = len(api_key)
    key_preview = api_key[:4] + "..." + api_key[-4:] if key_length > 8 else "***"

    print(f"✓ ODDS_API_KEY is set ({key_length} chars): {key_preview}")
    print(f"✓ Environment is ready for API client")

    return True

if __name__ == "__main__":
    print("=" * 60)
    print("  Odds API Environment Test")
    print("=" * 60)
    print()

    success = test_env_loading()

    print()
    print("=" * 60)

    if success:
        print("✅ All checks passed! Ready for Loop 5:2")
        sys.exit(0)
    else:
        print("❌ Some checks failed. Fix issues above.")
        sys.exit(1)
