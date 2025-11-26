#!/usr/bin/env python3
"""
Odds API Client

Quota-aware HTTP client for The Odds API with dry-run mode by default.
Follows canonical code style from current_cycle.md.
"""
import os
import requests
import time
from typing import Optional, Dict, Tuple, Any


class OddsAPI:
    """
    The Odds API client with dry-run mode and quota tracking.

    Features:
    - Dry-run mode by default (no API calls until explicitly enabled)
    - API key loaded from .env file
    - Quota header capture (x-requests-last, used, remaining)
    - 429 rate limit backoff (5 second retry)
    - Request logging for debugging

    Usage:
        # Dry-run mode (no real API calls)
        api = OddsAPI(dry_run=True)
        data, quota = api._request("/sports", {})
        # Prints: [DRY-RUN] GET https://... but doesn't call API

        # Real mode (consumes quota)
        api = OddsAPI(dry_run=False)
        data, quota = api._request("/sports", {})
        # Makes actual API call
    """

    BASE = "https://api.the-odds-api.com/v4"

    def __init__(self, dry_run: bool = True):
        """
        Initialize the Odds API client.

        Args:
            dry_run: If True, prints requests without making them (default: True)

        Raises:
            RuntimeError: If ODDS_API_KEY environment variable is not set
        """
        self.api_key = os.getenv("ODDS_API_KEY")
        if not self.api_key:
            raise RuntimeError("ODDS_API_KEY not set")
        self.dry_run = dry_run

    def _request(
        self,
        endpoint: str,
        params: Dict[str, Any]
    ) -> Tuple[Optional[Dict], Optional[Dict]]:
        """
        Make a request to The Odds API.

        Args:
            endpoint: API endpoint path (e.g., "/sports/americanfootball_nfl/odds")
            params: Query parameters (apiKey will be added automatically)

        Returns:
            Tuple of (response_data, quota_info)
            - In dry-run mode: (None, None)
            - In real mode: (JSON response, quota headers dict)

        Example:
            >>> api = OddsAPI(dry_run=True)
            >>> data, quota = api._request("/sports", {"sport": "americanfootball_nfl"})
            [DRY-RUN] GET https://api.the-odds-api.com/v4/sports params= {...}
            >>> data is None
            True
        """
        # Add API key to params
        params = {**params, "apiKey": self.api_key}
        url = f"{self.BASE}{endpoint}"

        # Dry-run mode: print request but don't execute
        if self.dry_run:
            print(f"[DRY-RUN] GET {url} params=", params)
            return None, None

        # Real mode: make actual HTTP request
        resp = requests.get(url, params=params)

        # Handle rate limiting (429 Too Many Requests)
        if resp.status_code == 429:
            print("[WARNING] Rate limit hit (429), retrying in 5 seconds...")
            time.sleep(5)
            return self._request(endpoint, params)

        # Raise exception for other HTTP errors
        resp.raise_for_status()

        # Capture quota information from response headers
        quota = {
            "last": resp.headers.get("x-requests-last"),
            "used": resp.headers.get("x-requests-used"),
            "remaining": resp.headers.get("x-requests-remaining")
        }

        return resp.json(), quota
