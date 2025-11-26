"""
Odds API Client Package

Provides quota-aware, dry-run-first access to The Odds API
for NFL historical and live odds data.

Modules (to be implemented in Loop 5:2+):
- client: Base OddsAPI class with dry-run mode
- events: Event ID caching (quota-free endpoint)
- historical: Historical odds fetcher
- processor: American odds to probability conversion
- batch: Batch runner with checkpointing
- weekly: Weekly updater (stretch goal)
"""
__version__ = "0.1.0"
