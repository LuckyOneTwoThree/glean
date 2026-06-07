<div align="center">

# 拾光 / Glean

**AI 驱动的个性化资讯简报应用**

自动采集 RSS 信源，智能评分筛选，生成每日简报 — 纯本地运行，无需后端

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?logo=sqlite)
![Riverpod](https://img.shields.io/badge/Riverpod-2.x-4A00E0)
![License](https://img.shields.io/badge/License-MIT-green)

中文 | [English](README_EN.md)

</div>

---

## 为什么需要拾光？

信息过载是个老问题。RSS 阅读器能聚合内容，但不帮你判断什么值得看。拾光做的事：按你设定的方向和来源抓文章，给每篇打分，把高分文章整理成一份每日简报。

整个流程在手机上完成。不需要注册，不需要服务器，数据存在本地 SQLite 里。评分和摘要可以用纯本地算法（免费），也可以接 LLM API（按量付费），LLM 挂了或者预算用完会自动降级到本地模式。

## 运行

```bash
git clone https://github.com/LuckyOneTwoThree/glean.git
cd glean
flutter pub get
flutter run
```

构建：

```bash
flutter build apk --release
flutter build ios --release
```

首次启动进入引导流程：欢迎 → 选择关注领域 → 选择数据源 → 配置偏好（AI 模式、国内外比例、每日数量）→ 配置 LLM（省钱模式可跳过）→ 生成第一份简报。

## 数据流

```
RSS 源列表
    │
    ▼
并发抓取（每批 5 源，30s 超时，失败重试 2 次）
    │
    ▼
XML 解析（RSS 2.0 / Atom 1.0 / RDF）→ 提取 title, link, description, content:encoded, pubDate, author
    │
    ▼
去重（URL 精确匹配 + 标题相似度 ≥ 0.75 则判定重复，保留来源可信度更高的）
    │
    ▼
入库 articles 表，同时从 description 提取一句话摘要
    │
    ▼
评分（本地规则 / LLM）→ 写入 scores 表，回写 articles.score_total
    │
    ▼
摘要（TextRank / LLM）→ 更新 articles.summary_one / summary_points
    │
    ▼
简报生成：领域过滤 → 评分 ≥ 3.0 → 国内外比例分配 → 评分降序取前 N 条
    │
    ▼
按领域分组展示 / 导出
```

## 评分机制

### 本地规则评分

```
total = credibility × 0.5 + density × 0.5
```

- **credibility**（来源可信度）：初始值 5.0，范围 1.0-10.0。受用户反馈动态调整："有用" +0.2，"没用" -0.5。新来源的初始可信度由 `feeds.credibility_weight` 决定
- **density**（信息密度）：基于正文长度、段落结构、代码块和数据占比计算。长文、有代码示例、有数据表格的文章密度分更高

### LLM 评分

调用 OpenAI 兼容接口，一次请求返回全部结果：

```json
{
  "score": {
    "source_credibility": 8,
    "information_density": 7,
    "overall": 7.5,
    "reason": "评分理由"
  },
  "summary": {
    "one_line": "一句话摘要",
    "bullets": ["要点1", "要点2", "要点3"]
  },
  "action": {
    "tag": "深入阅读",
    "reason": "行动理由"
  }
}
```

比分开调用评分和摘要省一半 token。LLM 评分后会把摘要和行动标签同步写回 articles 表，避免重复调用。

### 降级策略

- LLM 调用失败 → 降级到本地规则评分
- 月 token 用量超过预算（默认 10000）→ 降级到本地模式
- quality/hybrid 模式下摘要服务调用 LLM 失败 → 降级到 TextRank

## 摘要生成

### TextRank（本地模式）

1. 正文分句（按中英文标点），过滤长度 < 8 的短句
2. 中文 2-gram + 英文单词分词
3. 构建句子相似度矩阵（Jaccard 系数）
4. 迭代计算句子权重（阻尼系数 0.85，最多 30 轮，收敛阈值 0.0001）
5. 取权重最高的 3 句，按原文顺序排列，每句截断到 50 字

一句话摘要：优先取 description，截断到 60 字；没有则取正文首句。

### LLM 摘要

由 `scoreAndSummarize` 一起返回，不单独调用。LLM 失败时降级到 TextRank。

## 简报生成流程

`BriefingService.generate()` 的完整步骤：

1. 查找今日已有简报，有则复用 ID（刷新模式），无则新建
2. 调用 `FetchService.runFetch()` 采集最新文章
3. 对未评分文章调用 `ScoreService.scoreArticle()`
4. 对无摘要或 quality/hybrid 模式的文章调用 `SummaryService.summarize()`
5. 按关注领域过滤：先匹配文章 category 字段，再匹配标题+内容中的领域关键词（12 个领域，每个领域 10+ 关键词）。未匹配的文章保留，排在后面
6. 过滤评分 < 3.0 的文章
7. 按国内外比例分配名额：先查 feeds 表的 `is_domestic` 字段，再查 URL 域名，最后用来源名称匹配。某一方文章不足时名额顺延给另一方
8. 按评分降序排列
9. 生成 AI 洞察（统计领域分布、国内外比例）
10. 写入 briefings 表，关联文章

## 去重算法

两层去重：

1. **URL 精确匹配**：文章 URL 在数据库中已存在则跳过
2. **标题相似度**：对最近 7 天的文章（最多 500 条），计算新文章标题与已有标题的相似度

相似度公式：

```
similarity = 0.6 × jaccard(title_a, title_b) + 0.4 × edit_distance_sim(title_a, title_b)
```

- Jaccard：词级集合交集 / 并集
- 编辑距离相似度：`1 - edit_distance / max(len_a, len_b)`

阈值 0.75，超过则判定为重复。重复时比较来源可信度，新来源可信度更高则替换旧文章。

## AI 模式

| 模式 | 评分 | 摘要 | 费用 |
|------|------|------|------|
| economy | 本地规则 | TextRank | 0 |
| quality | LLM | LLM | 按 token |
| hybrid | 本地规则 | LLM | 低 |

省钱模式下所有计算在本地完成，不需要任何 API Key。质量模式下评分和摘要都走 LLM。混合模式评分用本地规则（快），摘要用 LLM（准）。

## 技术栈

Flutter + Riverpod + SQLite，没有后端。

| 能力 | 实现 |
|------|------|
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Riverpod |
| 数据库 | SQLite (sqflite)，schema v4 |
| 网络请求 | Dio |
| RSS 解析 | xml package，支持 RSS 2.0 / Atom 1.0 / RDF |
| LLM | OpenAI 兼容接口（MiMo / DeepSeek / OpenAI / 自定义） |
| 后台任务 | Workmanager（定时采集 + 简报推送） |
| 本地通知 | flutter_local_notifications |
| 导出 | archive (ZIP) + share_plus |
| 安全存储 | flutter_secure_storage（API Key） |

## 项目结构

```
lib/
├── main.dart                          应用入口，初始化 Workmanager 和通知
├── app.dart                           MaterialApp、主题、路由、定时任务注册
│
├── models/
│   ├── article.dart                   文章（title, url, content, summary_one, summary_points, score_total, action_tag, ...）
│   ├── feed.dart                      数据源（url, type, category, credibility, is_enabled, is_domestic, ...）
│   ├── briefing.dart                  简报（date, article_count, ai_insight, categories_json, ...）
│   ├── score.dart                     评分记录（credibility, density, total, raw_response, action_tag）
│   ├── user_config.dart               用户配置（categories, domestic_ratio, daily_count, ai_mode, push_time, ...）
│   ├── llm_config.dart                LLM 配置（provider, api_key, model, base_url, budget_tokens, ...）
│   ├── execution_log.dart             执行日志
│   ├── article_tag.dart               文章标签
│   └── llm_cost.dart                  LLM 调用成本
│
├── services/
│   ├── fetch_service.dart             RSS 采集、并发控制（每批 5 源）、重试（5min/15min）、去重、XML 解析、HTML 清洗
│   ├── score_service.dart             评分调度（本地/LLM）、降级、反馈记录、来源可信度调整
│   ├── summary_service.dart           TextRank 算法实现、LLM 摘要降级
│   ├── briefing_service.dart          简报生成、领域过滤、比例分配、AI 洞察
│   ├── llm_service.dart               API 调用、Prompt 构建、成本记录、预算检查、连接测试
│   ├── feed_service.dart              数据源 CRUD、启用/禁用、连通性测试
│   ├── export_service.dart            Markdown / JSON / ZIP 导出与分享
│   ├── database_service.dart          SQLite 建表、索引、v1→v4 迁移、种子数据、清空/重置
│   ├── schedule_service.dart          Workmanager 定时采集与简报推送、WiFi 策略
│   └── notification_service.dart      本地通知、权限请求（iOS/Android）
│
├── providers/
│   └── app_state_provider.dart        全局 Provider（articles, briefings, feeds, configs, scores, feedback）、
│                                      辅助函数（refreshData, runFetch, saveUserConfig, saveLLMConfig, ...）
│
├── screens/
│   ├── welcome_screen.dart            欢迎页（品牌展示 → 进入引导）
│   ├── onboarding_screen.dart         6 步引导：欢迎 → 领域 → 数据源 → 偏好 → LLM 配置 → 生成简报
│   ├── home_screen.dart               首页（文章列表、评分/时间排序、全部/未读/收藏筛选、今日简报卡片）
│   ├── briefing_screen.dart           简报详情（按领域分组、统计、导出、刷新、历史简报）
│   ├── article_detail_screen.dart     文章详情（评分解释、LLM 评分理由、行动标签、有用/没用反馈、导出）
│   ├── settings_screen.dart           设置（偏好、推送时间、采集配置、数据管理入口）
│   ├── llm_config_screen.dart         LLM 配置（提供商选择、API Key、模型、连接测试、月度成本监控）
│   ├── briefing_config_screen.dart    简报配置（领域、数量、比例）
│   ├── feed_select_screen.dart        数据源选择
│   ├── feed_add_screen.dart           添加自定义 RSS 源（URL 输入 + 连通性测试）
│   ├── fetch_settings_screen.dart     采集设置（频率、WiFi 策略）
│   ├── data_management_screen.dart    数据管理（清空文章、重置数据库、全量导出）
│   ├── favorites_screen.dart          收藏列表
│   ├── execution_logs_screen.dart     执行日志
│   ├── briefing_loading_screen.dart   简报生成进度页（三步动画）
│   └── briefing_generate_screen.dart  简报生成入口
│
├── widgets/
│   ├── article_card.dart              文章卡片（评分徽章、标题、摘要、来源、时间、收藏）
│   ├── score_badge.dart               评分徽章（颜色分级）
│   ├── shimmer.dart                   骨架屏
│   ├── confirm_dialog.dart            确认弹窗
│   ├── empty_state.dart               空状态
│   ├── export_modal.dart              导出选择弹窗
│   ├── loading_state.dart             加载状态
│   ├── page_header.dart               页面标题
│   ├── section_header.dart            分组标题
│   ├── stat_card.dart                 统计卡片
│   └── toggle_switch.dart             切换开关
│
└── utils/
    ├── html_utils.dart                HTML 标签剥离、实体解码、CDATA 清理
    └── snackbar_util.dart             SnackBar 工具
```

## 数据库

SQLite，schema v4，9 张表，逐版本迁移（v1→v2→v3→v4），升级不丢数据。

### articles

| 列 | 类型 | 说明 |
|----|------|------|
| id | TEXT PK | 唯一标识 |
| title | TEXT NOT NULL | 标题 |
| url | TEXT UNIQUE | 文章链接 |
| content | TEXT | 全文内容 |
| summary_one | TEXT | 一句话摘要（≤60 字） |
| summary_points | TEXT | 三要点（JSON 数组） |
| source_name | TEXT NOT NULL | 来源名称 |
| source_url | TEXT | 来源 RSS URL |
| category | TEXT | 文章领域 |
| published_at | INTEGER | 发布时间戳 |
| fetched_at | INTEGER | 采集时间戳 |
| score_total | REAL DEFAULT 0 | 总评分 |
| score_credibility | REAL DEFAULT 0 | 可信度分 |
| score_density | REAL DEFAULT 0 | 信息密度分 |
| score_mode | TEXT DEFAULT 'local' | 评分模式（local/llm） |
| is_read | INTEGER DEFAULT 0 | 已读 |
| is_favorited | INTEGER DEFAULT 0 | 收藏 |
| is_fulltext | INTEGER DEFAULT 1 | 是否全文 |
| merged_article_ids | TEXT | 合并的文章 ID |
| briefing_id | TEXT | 关联简报 |
| action_tag | TEXT | 行动建议标签 |

### feeds

| 列 | 类型 | 说明 |
|----|------|------|
| id | TEXT PK | 唯一标识（预置源用 preset_ 前缀） |
| name | TEXT NOT NULL | 来源名称 |
| url | TEXT UNIQUE | RSS URL |
| type | TEXT NOT NULL | 类型（rss/atom/api） |
| category | TEXT | 领域分类 |
| is_enabled | INTEGER DEFAULT 1 | 是否启用 |
| is_preset | INTEGER DEFAULT 0 | 是否预置源 |
| credibility_weight | REAL DEFAULT 3.0 | 初始可信度权重 |
| credibility | REAL DEFAULT 5.0 | 当前可信度（1.0-10.0） |
| is_domestic | INTEGER DEFAULT 1 | 是否国内源 |
| last_fetched_at | INTEGER | 上次采集时间 |
| fetch_error_count | INTEGER DEFAULT 0 | 连续错误次数 |
| status | TEXT DEFAULT 'active' | 状态 |

### briefings

| 列 | 类型 | 说明 |
|----|------|------|
| id | TEXT PK | 唯一标识 |
| date | TEXT NOT NULL | 日期（YYYY-MM-DD） |
| article_count | INTEGER | 文章数 |
| config_snapshot | TEXT | 生成时配置快照 |
| generated_at | INTEGER | 生成时间戳 |
| trigger_type | TEXT | 触发方式（auto/scheduled/manual） |
| status | TEXT | 状态（generating/completed/failed） |
| ai_insight | TEXT | AI 洞察文本 |
| total_fetched | INTEGER | 采集总数 |
| domestic_count | INTEGER | 国内文章数 |
| international_count | INTEGER | 国际文章数 |
| categories_json | TEXT | 领域分布 JSON |

### 其他表

- **scores**：评分记录（article_id, mode, credibility, density, total, raw_response, action_tag, scored_at）
- **user_config**：用户配置（categories, daily_count, domestic_ratio, ai_mode, push_time, fetch_interval, wifi_only, retention_days）
- **llm_config**：LLM 配置（provider, api_key, model, base_url, timeout, budget_tokens）
- **llm_costs**：LLM 调用成本（operation, model, input_tokens, output_tokens, created_at）
- **user_feedback**：用户反馈（article_id, feedback_type, created_at）
- **execution_logs**：执行日志（task_type, status, started_at, completed_at, duration, error_message）

## 预置数据源

12 个预置源，覆盖国内外主流科技媒体：

| 数据源 | 领域 | 地域 |
|--------|------|------|
| Hacker News | 技术 | 国际 |
| TechCrunch | 科技商业 | 国际 |
| The Verge | 消费科技 | 国际 |
| Ars Technica | 技术 | 国际 |
| The Hacker News | 安全 | 国际 |
| Dev.to | 开发者 | 国际 |
| 少数派 (sspai) | 效率工具 | 国内 |
| 36氪 | 科技商业 | 国内 |
| 机器之心 | AI | 国内 |
| InfoQ 中文 | 技术 | 国内 |
| 奇安信威胁情报 | 安全 | 国内 |
| 即刻热门 | 综合 | 国内 |

可以添加任意 RSS/Atom 源，添加时会测试连通性。

## 关注领域

12 个方向，每个方向有对应的关键词列表用于文章匹配：

AI、科技商业、技术、消费科技、前沿科技、效率工具、综合科技、开源生态、产品与设计、安全与隐私、云与基础设施、科技文化

领域过滤采用宽松模式：匹配领域的文章优先排列，未匹配的保留在后面补充，确保简报数量充足。

## 导出

| 类型 | 格式 | 内容 |
|------|------|------|
| 单篇文章 | Markdown / JSON | 标题、评分、一句话摘要、三要点、全文、来源、时间 |
| 每日简报 | Markdown / JSON | 按领域分组、统计信息、AI 洞察、每篇文章的摘要 |
| 全量备份 | ZIP | meta.json + articles.json + briefings.json + scores.json + feeds.json + logs.json |

导出文件通过系统分享面板发送到其他应用。

## 反馈闭环

文章详情页有"有用/没用"按钮。反馈写入 `user_feedback` 表，同时调整来源可信度：

- "有用" → 来源 credibility +0.2
- "没用" → 来源 credibility -0.5

可信度变化直接影响后续文章的本地评分和简报入选概率。来源连续被标记"没用"后，其文章评分会越来越低，最终自然被简报淘汰。

## 后台任务

基于 Workmanager 实现：

- **定时采集**：可配置间隔（1h / 2h / 4h / 手动），支持仅 WiFi 模式（`NetworkType.unmetered`）
- **简报推送**：可配置推送时间（默认 08:00），到时间自动采集 + 生成 + 发送本地通知
- 简报推送用 `OneOffTask` + 初始延迟实现，执行完后自动注册第二天的任务

## License

MIT
