# Odds API Client

Quota-aware, dry-run-first Python client for The Odds API to fetch NFL historical and live odds data.

## 🎯 Goal 5 Objectives

Build a robust historical odds pipeline with:
- Immutable archives by season (2022-2025)
- American odds → probability conversion
- Free-tier testing before paid calls
- Quota protection and cost prediction

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# From project root
pip install -r requirements.txt
```

**Core dependencies**:
- `requests` - HTTP client
- `python-dotenv` - Environment variable loading
- `pandas` + `pyarrow` - Data processing and parquet files

### 2. Configure API Key

Edit `.env` file in project root:

```bash
# Get your API key from https://the-odds-api.com/
ODDS_API_KEY=your_actual_key_here
```

**Free Tier**: 500 requests/month - perfect for testing!

### 3. Test Environment

```bash
python3 src/odds_api/test_env.py
```

Should output:
```
✓ python-dotenv is installed
✓ .env file found
✓ ODDS_API_KEY is set
✅ All checks passed! Ready for Loop 5:2
```

## 📦 Package Structure

```
src/odds_api/
├── __init__.py           # Package initialization
├── README.md             # This file
├── test_env.py           # Environment test script
├── client.py             # Base OddsAPI class (Loop 5:2)
├── events.py             # Event ID caching (Loop 5:3)
├── historical.py         # Historical odds fetcher (Loop 5:4+)
├── processor.py          # Odds → probability conversion
├── batch.py              # Batch runner with checkpointing
└── weekly.py             # Weekly updater (stretch goal)
```

## 🛡️ Guardrails

### 1. Quota Protection
- **DRY-RUN MODE by default** until human approval
- Free-tier testing first (500 requests/month)
- Cost prediction before batch operations
- Historical odds are EXPENSIVE (10 requests per game)

### 2. API Key Security
- ✅ DO: Store in `.env` file (gitignored)
- ✅ DO: Load via `os.getenv("ODDS_API_KEY")`
- ❌ DON'T: Print key in logs
- ❌ DON'T: Hardcode in source files
- ❌ DON'T: Commit to repo

### 3. Immutable Archives
Once a season's data is validated and archived:
- ❌ No edits allowed
- ❌ No deletions allowed
- ❌ No renames allowed
- ✅ Read-only access only

Archive structure:
```
data/raw/odds_2022/20241125_143022/
data/raw/odds_2023/20241125_143023/
data/raw/odds_2024/20241125_143024/
data/raw/odds_2025/20241125_143025/
```

## 🔌 API Endpoints

### Free Tier (Low Cost)
- `/v4/sports/americanfootball_nfl/odds` - Current odds
- `/v4/sports/americanfootball_nfl/events` - **Quota-free** event listing

### Paid Tier (High Cost)
- `/v4/historical/sports/americanfootball_nfl/events/{eventId}/odds` - Historical odds
  - Cost: 10 requests per game (with bookmakers filter)
  - 2022-2025: ~1000 games = ~10,000 requests total
  - Use free tier to validate pipeline first!

## 📊 Data Flow

```
1. Events Endpoint (quota-free)
   → Get event IDs for all NFL games 2022-2025
   → Cache to data/processed/event_ids/{season}.json

2. Historical Endpoint (expensive)
   → Fetch odds snapshots for each event
   → Filter to top 5 bookmakers (fanduel, draftkings, caesars, betmgm, pointsbetus)
   → Only h2h market (moneyline)
   → Store raw JSON in immutable archives

3. Processing
   → Select final odds (≤ kickoff time)
   → Convert American odds to probabilities
   → Combine all seasons into parquet
   → Output: data/processed/odds/all_seasons_{timestamp}.parquet

4. Weekly Updates (stretch)
   → Use free-tier /odds endpoint for new games
   → Append to data/processed/live_updates.parquet
```

## 🧪 Testing Strategy

### Loop 5:1-5:4: Setup & Dry-Run
- Build API client with dry-run mode
- Test URL construction
- Validate parameter handling
- No real API calls

### Loop 5:5: Pilot (2 games)
- First real API calls (human approved)
- Validate quota headers
- Confirm data schema
- Test probability conversion

### Loop 5:6+: Full Extraction
- Batch runner with checkpointing
- Season-by-season extraction
- Immutable archive validation
- Combined parquet output

## 📝 Loop Progress

- **Loop 5:1**: Setup & PR Init ✅ COMPLETED
  - Branch created
  - `.env` file ready
  - Guardrails documented
  - Dependencies specified
  - Test script created

- **Loop 5:2**: API Client Scaffolding (Next)
  - Create `client.py` with OddsAPI class
  - Dry-run mode by default
  - Quota header capture
  - 429 rate limit backoff

- **Loop 5:3**: Events Endpoint
  - Event ID caching (quota-free)
  - Season filtering
  - Kickoff timestamp validation

- **Loop 5:4**: Historical Test Harness
  - Dry-run cost prediction
  - Bookmaker filtering
  - URL construction tests

- **Loop 5:5**: Pilot Pull
  - 2 games (human approved)
  - First real historical calls
  - Quota validation

## 🔧 Development

### Running Tests (when implemented)
```bash
pytest src/odds_api/
```

### Type Checking (optional)
```bash
mypy src/odds_api/
```

### Code Formatting (optional)
```bash
black src/odds_api/
flake8 src/odds_api/
```

## 📚 Resources

- **The Odds API Docs**: https://the-odds-api.com/liveapi/guides/v4/
- **Free Tier Signup**: https://the-odds-api.com/
- **NFL Season**: 17 weeks regular season + playoffs
- **Data Coverage**: 2022 W12-18, 2023-2025 full seasons

## 🆘 Troubleshooting

### "python-dotenv not installed"
```bash
pip install python-dotenv
```

### "ODDS_API_KEY not set"
1. Check `.env` file exists in project root
2. Ensure `ODDS_API_KEY=your_key` is set (not the placeholder)
3. Run test: `python3 src/odds_api/test_env.py`

### "Module not found" errors
```bash
# Ensure you're in project root
cd /Users/derekdebellis/Desktop/dev-projects/meta-model-v2

# Install all dependencies
pip install -r requirements.txt
```

### Free tier quota exhausted
- Wait for monthly reset
- Upgrade to paid tier if needed for historical data
- Historical odds require paid tier anyway (free tier doesn't have historical endpoint)

---

**Status**: Loop 5:1 ✅ COMPLETE
**Next**: Loop 5:2 - API Client Scaffolding
**Branch**: `feat/goal5-odds-pipeline`
**PR**: #11 (DRAFT)
