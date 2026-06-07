<div align="center">

# Glean

**AI-Powered Personalized News Briefing App**

Automated RSS fetching, intelligent scoring, and daily briefing generation — runs entirely on-device, no backend required

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?logo=sqlite)
![Riverpod](https://img.shields.io/badge/Riverpod-2.x-4A00E0)
![License](https://img.shields.io/badge/License-MIT-green)

English | [中文](README.md)

</div>

---

## Why Glean?

Information overload is an old problem. RSS readers aggregate content but don't tell you what's worth reading. Glean fetches articles from sources you choose, scores each one, and compiles the highest-scoring articles into a daily briefing.

Everything runs on your phone. No registration, no server. Data lives in a local SQLite database. Scoring and summarization can use on-device algorithms (free) or LLM APIs (pay-per-token). If the LLM fails or the budget runs out, it automatically degrades to local mode.

## Getting Started

```bash
git clone https://github.com/LuckyOneTwoThree/glean.git
cd glean
flutter pub get
flutter run
```

Building:

```bash
flutter build apk --release
flutter build ios --release
```

First launch goes through onboarding: Welcome → Select topics → Select sources → Configure preferences (AI mode, domestic/international ratio, daily count) → Configure LLM (skippable in economy mode) → Generate first briefing.

## Data Flow

```
RSS source list
    │
    ▼
Concurrent fetching (5 sources per batch, 30s timeout, 2 retries)
    │
    ▼
XML parsing (RSS 2.0 / Atom 1.0 / RDF) → extract title, link, description, content:encoded, pubDate, author
    │
    ▼
Deduplication (URL exact match + title similarity ≥ 0.75 → keep higher-credibility source)
    │
    ▼
Insert into articles table, extract one-line summary from description
    │
    ▼
Scoring (local rules / LLM) → write to scores table, update articles.score_total
    │
    ▼
Summarization (TextRank / LLM) → update articles.summary_one / summary_points
    │
    ▼
Briefing generation: topic filter → score ≥ 3.0 → domestic/international ratio allocation → top N by score
    │
    ▼
Group by topic / export
```

## Scoring

### Local Rule-Based Scoring

```
total = credibility × 0.5 + density × 0.5
```

- **credibility** (source credibility): initial value 5.0, range 1.0–10.0. Dynamically adjusted by user feedback: "useful" +0.2, "not useful" -0.5. Initial credibility for new sources is determined by `feeds.credibility_weight`
- **density** (information density): calculated from body length, paragraph structure, code block and data ratios. Longer articles with code examples and data tables score higher

### LLM Scoring

Calls an OpenAI-compatible API, returning all results in a single request:

```json
{
  "score": {
    "source_credibility": 8,
    "information_density": 7,
    "overall": 7.5,
    "reason": "Scoring rationale"
  },
  "summary": {
    "one_line": "One-line summary",
    "bullets": ["Point 1", "Point 2", "Point 3"]
  },
  "action": {
    "tag": "Read in depth",
    "reason": "Action rationale"
  }
}
```

This saves roughly half the tokens compared to separate scoring and summarization calls. After LLM scoring, summaries and action tags are written back to the articles table to avoid redundant calls.

### Degradation Strategy

- LLM call fails → fall back to local rule-based scoring
- Monthly token usage exceeds budget (default 10000) → degrade to local mode
- LLM summarization fails in quality/hybrid mode → fall back to TextRank

## Summarization

### TextRank (Local Mode)

1. Split text into sentences (by CJK and English punctuation), filter sentences shorter than 8 characters
2. Chinese 2-gram + English word tokenization
3. Build sentence similarity matrix (Jaccard coefficient)
4. Iteratively compute sentence weights (damping factor 0.85, max 30 iterations, convergence threshold 0.0001)
5. Take top 3 weighted sentences, arrange in original order, truncate each to 50 characters

One-line summary: prefer `description` field, truncate to 60 characters; fall back to first sentence of body.

### LLM Summarization

Returned together by `scoreAndSummarize`, never called separately. Falls back to TextRank on LLM failure.

## Briefing Generation

`BriefingService.generate()` step by step:

1. Look up today's briefing — reuse ID if it exists (refresh mode), otherwise create new
2. Call `FetchService.runFetch()` to fetch latest articles
3. Score unscored articles via `ScoreService.scoreArticle()`
4. Summarize articles without summaries, or in quality/hybrid mode, via `SummaryService.summarize()`
5. Filter by followed topics: first match article `category` field, then match topic keywords in title + content (12 topics, 10+ keywords each). Unmatched articles are kept but ranked lower
6. Filter out articles scoring below 3.0
7. Allocate slots by domestic/international ratio: check `feeds.is_domestic` first, then URL domain, then source name. Unused slots from one side roll over to the other
8. Sort by score descending
9. Generate AI insight (topic distribution, domestic/international ratio stats)
10. Write to briefings table, link articles

## Deduplication

Two layers:

1. **URL exact match**: skip if article URL already exists in database
2. **Title similarity**: compare against articles from the last 7 days (up to 500), compute similarity with existing titles

Similarity formula:

```
similarity = 0.6 × jaccard(title_a, title_b) + 0.4 × edit_distance_sim(title_a, title_b)
```

- Jaccard: word-level set intersection / union
- Edit distance similarity: `1 - edit_distance / max(len_a, len_b)`

Threshold 0.75 — above this, articles are considered duplicates. When duplicates are found, the source with higher credibility is kept.

## AI Modes

| Mode | Scoring | Summarization | Cost |
|------|---------|---------------|------|
| economy | Local rules | TextRank | 0 |
| quality | LLM | LLM | Per-token |
| hybrid | Local rules | LLM | Low |

Economy mode runs everything on-device, no API key needed. Quality mode uses LLM for both scoring and summarization. Hybrid mode uses local rules for scoring (fast) and LLM for summarization (accurate).

## Tech Stack

Flutter + Riverpod + SQLite, no backend.

| Capability | Implementation |
|------------|---------------|
| Framework | Flutter 3.x (Dart) |
| State management | Riverpod |
| Database | SQLite (sqflite), schema v4 |
| HTTP | Dio |
| RSS parsing | xml package, supports RSS 2.0 / Atom 1.0 / RDF |
| LLM | OpenAI-compatible API (MiMo / DeepSeek / OpenAI / custom) |
| Background tasks | Workmanager (scheduled fetch + briefing push) |
| Local notifications | flutter_local_notifications |
| Export | archive (ZIP) + share_plus |
| Secure storage | flutter_secure_storage (API key) |

## Project Structure

```
lib/
├── main.dart                          App entry, initializes Workmanager and notifications
├── app.dart                           MaterialApp, themes, routing, schedule registration
│
├── models/
│   ├── article.dart                   Article (title, url, content, summary_one, summary_points, score_total, action_tag, ...)
│   ├── feed.dart                      Feed source (url, type, category, credibility, is_enabled, is_domestic, ...)
│   ├── briefing.dart                  Briefing (date, article_count, ai_insight, categories_json, ...)
│   ├── score.dart                     Score record (credibility, density, total, raw_response, action_tag)
│   ├── user_config.dart               User config (categories, domestic_ratio, daily_count, ai_mode, push_time, ...)
│   ├── llm_config.dart                LLM config (provider, api_key, model, base_url, budget_tokens, ...)
│   ├── execution_log.dart             Execution log
│   ├── article_tag.dart               Article tag
│   └── llm_cost.dart                  LLM call cost
│
├── services/
│   ├── fetch_service.dart             RSS fetching, concurrency (5 per batch), retry (5min/15min), dedup, XML parsing, HTML cleaning
│   ├── score_service.dart             Score dispatch (local/LLM), degradation, feedback, credibility adjustment
│   ├── summary_service.dart           TextRank implementation, LLM summary degradation
│   ├── briefing_service.dart          Briefing generation, topic filtering, ratio allocation, AI insight
│   ├── llm_service.dart               API calls, prompt construction, cost tracking, budget check, connectivity test
│   ├── feed_service.dart              Feed CRUD, enable/disable, connectivity test
│   ├── export_service.dart            Markdown / JSON / ZIP export and sharing
│   ├── database_service.dart          SQLite schema, indexes, v1→v4 migration, seed data, wipe/reset
│   ├── schedule_service.dart          Workmanager scheduled fetch and briefing push, WiFi policy
│   └── notification_service.dart      Local notifications, permission request (iOS/Android)
│
├── providers/
│   └── app_state_provider.dart        Global providers (articles, briefings, feeds, configs, scores, feedback),
│                                      helper functions (refreshData, runFetch, saveUserConfig, saveLLMConfig, ...)
│
├── screens/
│   ├── welcome_screen.dart            Welcome (brand splash → enter onboarding)
│   ├── onboarding_screen.dart         6-step onboarding: welcome → topics → sources → preferences → LLM config → generate briefing
│   ├── home_screen.dart               Home (article list, score/time sort, all/unread/favorites filter, today's briefing card)
│   ├── briefing_screen.dart           Briefing detail (grouped by topic, stats, export, refresh, history)
│   ├── article_detail_screen.dart     Article detail (score explanation, LLM rationale, action tag, useful/not useful feedback, export)
│   ├── settings_screen.dart           Settings (preferences, push time, fetch config, data management)
│   ├── llm_config_screen.dart         LLM config (provider, API key, model, connectivity test, monthly cost monitoring)
│   ├── briefing_config_screen.dart    Briefing config (topics, count, ratio)
│   ├── feed_select_screen.dart        Feed source selection
│   ├── feed_add_screen.dart           Add custom RSS source (URL input + connectivity test)
│   ├── fetch_settings_screen.dart     Fetch settings (interval, WiFi policy)
│   ├── data_management_screen.dart    Data management (clear articles, reset database, full export)
│   ├── favorites_screen.dart          Favorites list
│   ├── execution_logs_screen.dart     Execution logs
│   ├── briefing_loading_screen.dart   Briefing generation progress (3-step animation)
│   └── briefing_generate_screen.dart  Briefing generation entry
│
├── widgets/
│   ├── article_card.dart              Article card (score badge, title, summary, source, time, favorite)
│   ├── score_badge.dart               Score badge (color-coded)
│   ├── shimmer.dart                   Shimmer placeholder
│   ├── confirm_dialog.dart            Confirm dialog
│   ├── empty_state.dart               Empty state
│   ├── export_modal.dart              Export selection modal
│   ├── loading_state.dart             Loading state
│   ├── page_header.dart               Page header
│   ├── section_header.dart            Section header
│   ├── stat_card.dart                 Stat card
│   └── toggle_switch.dart             Toggle switch
│
└── utils/
    ├── html_utils.dart                HTML tag stripping, entity decoding, CDATA cleanup
    └── snackbar_util.dart             SnackBar utility
```

## Database

SQLite, schema v4, 9 tables, incremental migration (v1→v2→v3→v4), no data loss on upgrade.

### articles

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique identifier |
| title | TEXT NOT NULL | Title |
| url | TEXT UNIQUE | Article URL |
| content | TEXT | Full text |
| summary_one | TEXT | One-line summary (≤60 chars) |
| summary_points | TEXT | Three key points (JSON array) |
| source_name | TEXT NOT NULL | Source name |
| source_url | TEXT | Source RSS URL |
| category | TEXT | Topic category |
| published_at | INTEGER | Publish timestamp |
| fetched_at | INTEGER | Fetch timestamp |
| score_total | REAL DEFAULT 0 | Total score |
| score_credibility | REAL DEFAULT 0 | Credibility score |
| score_density | REAL DEFAULT 0 | Density score |
| score_mode | TEXT DEFAULT 'local' | Scoring mode (local/llm) |
| is_read | INTEGER DEFAULT 0 | Read flag |
| is_favorited | INTEGER DEFAULT 0 | Favorite flag |
| is_fulltext | INTEGER DEFAULT 1 | Full text flag |
| merged_article_ids | TEXT | Merged article IDs |
| briefing_id | TEXT | Linked briefing |
| action_tag | TEXT | Action suggestion tag |

### feeds

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique identifier (preset sources use preset_ prefix) |
| name | TEXT NOT NULL | Source name |
| url | TEXT UNIQUE | RSS URL |
| type | TEXT NOT NULL | Type (rss/atom/api) |
| category | TEXT | Topic category |
| is_enabled | INTEGER DEFAULT 1 | Enabled flag |
| is_preset | INTEGER DEFAULT 0 | Preset source flag |
| credibility_weight | REAL DEFAULT 3.0 | Initial credibility weight |
| credibility | REAL DEFAULT 5.0 | Current credibility (1.0–10.0) |
| is_domestic | INTEGER DEFAULT 1 | Domestic source flag |
| last_fetched_at | INTEGER | Last fetch timestamp |
| fetch_error_count | INTEGER DEFAULT 0 | Consecutive error count |
| status | TEXT DEFAULT 'active' | Status |

### briefings

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique identifier |
| date | TEXT NOT NULL | Date (YYYY-MM-DD) |
| article_count | INTEGER | Article count |
| config_snapshot | TEXT | Config snapshot at generation time |
| generated_at | INTEGER | Generation timestamp |
| trigger_type | TEXT | Trigger type (auto/scheduled/manual) |
| status | TEXT | Status (generating/completed/failed) |
| ai_insight | TEXT | AI insight text |
| total_fetched | INTEGER | Total fetched count |
| domestic_count | INTEGER | Domestic article count |
| international_count | INTEGER | International article count |
| categories_json | TEXT | Topic distribution JSON |

### Other Tables

- **scores**: Score records (article_id, mode, credibility, density, total, raw_response, action_tag, scored_at)
- **user_config**: User config (categories, daily_count, domestic_ratio, ai_mode, push_time, fetch_interval, wifi_only, retention_days)
- **llm_config**: LLM config (provider, api_key, model, base_url, timeout, budget_tokens)
- **llm_costs**: LLM call costs (operation, model, input_tokens, output_tokens, created_at)
- **user_feedback**: User feedback (article_id, feedback_type, created_at)
- **execution_logs**: Execution logs (task_type, status, started_at, completed_at, duration, error_message)

## Preset Sources

12 preset sources covering major domestic and international tech media:

| Source | Topic | Region |
|--------|-------|--------|
| Hacker News | Tech | International |
| TechCrunch | Tech Business | International |
| The Verge | Consumer Tech | International |
| Ars Technica | Tech | International |
| The Hacker News | Security | International |
| Dev.to | Developer | International |
| sspai | Productivity | Domestic (CN) |
| 36Kr | Tech Business | Domestic (CN) |
| Jiqizhixin | AI | Domestic (CN) |
| InfoQ CN | Tech | Domestic (CN) |
| QiAnXin Threat Intel | Security | Domestic (CN) |
| Jike Hot | General | Domestic (CN) |

You can add any RSS/Atom source — connectivity is tested on addition.

## Topics

12 directions, each with a keyword list for article matching:

AI, Tech Business, Tech, Consumer Tech, Frontier Tech, Productivity, General Tech, Open Source, Product & Design, Security & Privacy, Cloud & Infrastructure, Tech Culture

Topic filtering uses a lenient mode: articles matching followed topics are prioritized, unmatched articles are kept as supplements to ensure sufficient briefing content.

## Export

| Type | Format | Content |
|------|--------|---------|
| Single article | Markdown / JSON | Title, score, one-line summary, three key points, full text, source, time |
| Daily briefing | Markdown / JSON | Grouped by topic, stats, AI insight, per-article summaries |
| Full backup | ZIP | meta.json + articles.json + briefings.json + scores.json + feeds.json + logs.json |

Exported files are sent to other apps via the system share sheet.

## Feedback Loop

Article detail pages have "Useful / Not useful" buttons. Feedback is written to the `user_feedback` table and adjusts source credibility:

- "Useful" → source credibility +0.2
- "Not useful" → source credibility -0.5

Credibility changes directly affect subsequent local scoring and briefing selection probability. Sources consistently marked "not useful" see their articles score progressively lower until they're naturally excluded from briefings.

## Background Tasks

Built on Workmanager:

- **Scheduled fetch**: configurable interval (1h / 2h / 4h / manual), supports WiFi-only mode (`NetworkType.unmetered`)
- **Briefing push**: configurable push time (default 08:00), automatically fetches + generates + sends local notification at the scheduled time
- Briefing push uses `OneOffTask` with initial delay, and automatically re-registers the next day's task after execution

## License

MIT
