# 拾光 / Glean — 产品需求文档（PRD）

> AI 驱动的个性化资讯简报应用
> 文档版本：v1.0 | 日期：2026-06-06
> 本文档为 AI Agent 开发支撑文档，包含完整的产品定义、数据模型、技术架构、UI 流程和验收标准。

---

## 目录

1. [产品概述](#1-产品概述)
2. [目标用户与使用场景](#2-目标用户与使用场景)
3. [信息架构](#3-信息架构)
4. [功能规格（P0 MVP）](#4-功能规格p0-mvp)
5. [功能规格（P1 增强）](#5-功能规格p1-增强)
6. [功能规格（P2/P3 远期）](#6-功能规格p2p3-远期)
7. [数据模型](#7-数据模型)
8. [AI 引擎设计](#8-ai-引擎设计)
9. [技术架构](#9-技术架构)
10. [UI/UX 流程](#10-uiux-流程)
11. [数据源清单](#11-数据源清单)
12. [配置默认值](#12-配置默认值)
13. [错误处理与边界情况](#13-错误处理与边界情况)
14. [性能要求](#14-性能要求)
15. [安全与隐私](#15-安全与隐私)
16. [验收标准](#16-验收标准)

---

## 1. 产品概述

### 1.1 产品定位

拾光（Glean）是一款 AI 驱动的个性化资讯简报应用。核心理念：**不是更多资讯，而是更准资讯**。

用户定义关注方向和规则，系统自动采集、AI 分析质量、生成每日简报，帮助用户从海量信息中拾取有价值的光。

### 1.2 核心价值

- **个性化**：用户定义关注领域、来源、比例，系统按规则执行
- **AI 质量分析**：自动评分筛选，只推值得看的内容
- **本地优先**：核心功能纯本地运行，数据自主可控
- **零成本可运行**：省钱模式下完全免费，LLM 模式按需付费

### 1.3 产品形态

- **平台**：iOS + Android（Flutter 跨平台）
- **部署**：纯手机端，无独立后端服务器
- **数据**：本地 SQLite 存储
- **AI**：本地规则引擎 + 远程 LLM API（可选）

### 1.4 功能总览

| 优先级 | 数量 | 阶段 | 核心能力 |
|--------|------|------|----------|
| P0 | 9 | MVP | 采集 → AI 评分 → 简报 → 导出 |
| P1 | 15 | MVP 增强 | 收藏、已读、行动建议、事件时间线、成本管理 |
| P2 | 6 | V2 差异化 | Webhook、待办同步、探索推荐、REST API |
| P3 | 5 | V3 长期 | 语义搜索、问答、知识图谱、笔记 |
| **合计** | **35** | — | — |

---

## 2. 目标用户与使用场景

### 2.1 目标用户画像

**主要用户**：信息密集型工作者（科技从业者、投资者、研究员、创业者）

特征：
- 每天需要跟踪多个信息源
- 信息过载导致效率低下
- 希望 AI 帮助筛选高价值内容
- 重视数据隐私和自主控制

### 2.2 核心使用场景

| 场景 | 触发 | 期望结果 |
|------|------|----------|
| **晨间简报** | 用户早上打开 App | 查看今日 AI 精选的 15-20 条高价值资讯 |
| **碎片浏览** | 通勤/等待时打开 App | 快速浏览资讯列表，已读/未读清晰 |
| **深度阅读** | 对某条资讯感兴趣 | 查看摘要 → 点击阅读原文 → 收藏 |
| **配置调整** | 发现关注领域变化 | 修改关注方向、来源、比例，立即生效 |
| **数据导出** | 需要备份或分享 | 导出简报/文章为 JSON/Markdown |
| **回顾追踪** | 想了解某事件发展 | 查看事件时间线，了解来龙去脉 |

### 2.3 使用频率

- **每日**：查看简报、浏览资讯列表
- **每周**：调整配置、查看兴趣画像
- **每月**：导出数据、清理存储

---

## 3. 信息架构

### 3.1 App 页面结构

```
拾光 App
├── 首页（Tab 1）
│   ├── 今日简报卡片
│   ├── 资讯列表（按评分/时间排序）
│   └── 筛选器（未读/收藏/领域）
│
├── 简报（Tab 2）
│   ├── 今日简报详情
│   ├── 历史简报列表
│   └── 简报详情页
│
├── 收藏（Tab 3）
│   └── 收藏文章列表
│
└── 设置（Tab 4）
    ├── 简报配置
    │   ├── 关注领域
    │   ├── 数据源管理
    │   ├── 国内/国际比例
    │   └── 每日总量
    ├── AI 模式
    │   ├── 模式切换（省钱/质量/混合）
    │   ├── LLM 提供商配置
    │   └── 成本监控
    ├── 数据管理
    │   ├── 导出
    │   ├── 存储占用
    │   └── 数据清理
    ├── 采集设置
    │   ├── 采集频率
    │   └── 网络策略
    └── 执行记录
```

### 3.2 导航模式

- **底部 Tab 导航**：首页、简报、收藏、设置（4 个 Tab）
- **页面跳转**：资讯卡片 → 资讯详情页；简报卡片 → 简报详情页
- **模态弹窗**：评分解释面板、导出选项、确认对话框

---

## 4. 功能规格（P0 MVP）

### 4.1 多源资讯采集

**功能描述**：从用户配置的 RSS/Atom 源和第三方新闻 API 自动采集资讯。

**用户故事**：
- 作为用户，我希望能添加/删除 RSS 源，以便控制信息来源
- 作为用户，我希望系统自动定时采集，以便无需手动操作

**详细规则**：

| 项目 | 规格 |
|------|------|
| 支持格式 | RSS 2.0、Atom 1.0、RDF |
| 采集方式 | HTTP GET，超时 30 秒 |
| 采集频率 | 默认每 2 小时，可配置（1h/2h/4h/手动） |
| 网络策略 | 默认仅 WiFi，可配置允许移动网络 |
| 失败重试 | 最多 3 次，间隔 5/15/30 分钟 |
| 并发限制 | 同时最多 5 个源 |
| 用户源管理 | 添加/编辑/删除/启用/禁用 |
| 预置源 | 默认启用 10+ 主流科技 RSS 源 |

**采集流程**：

```
1. 获取用户启用的 RSS 源列表
2. 并发请求各源（Dio，超时 30s）
3. 解析 RSS/Atom XML
4. 提取：title, link, description, pubDate, author, content
5. 对每条资讯执行去重检查（→ 4.2）
6. 新资讯入库，标记 fetched_at
7. 记录采集日志（成功数/失败数/耗时）
```

**边界情况**：

| 场景 | 处理方式 |
|------|----------|
| RSS 源 URL 无效 | 标记为"连接失败"，不删除，提醒用户 |
| RSS 源返回非 XML | 记录错误，跳过该源 |
| 网络不可用 | 跳过采集，记录日志，下次重试 |
| 源返回空列表 | 正常处理，记录"无新内容" |
| pubDate 缺失 | 使用 fetched_at 作为发布时间 |
| content:encoded 与 description 都有 | 优先使用 content:encoded 作为正文 |

**验收标准**：
- [ ] 能成功解析 RSS 2.0 和 Atom 1.0 格式
- [ ] 用户可添加自定义 RSS 源（输入 URL，自动验证）
- [ ] 采集结果正确入库，包含 title/link/description/content/pubDate/source_id
- [ ] 采集失败时记录错误日志，不影响其他源
- [ ] 支持禁用/启用单个源

---

### 4.2 资讯入库与去重

**功能描述**：将采集到的资讯存入本地数据库，自动去除重复内容。

**用户故事**：
- 作为用户，我希望同一条新闻不出现多次，以便不浪费时间

**去重算法**：

```
步骤 1：精确去重
  - 条件：link 完全相同
  - 动作：跳过，不入库

步骤 2：相似度去重
  - 计算：标题 Jaccard 相似度（分词后）+ 编辑距离归一化
  - Jaccard(A, B) = |A ∩ B| / |A ∪ B|
  - 编辑距离归一化 = 1 - (edit_distance / max(len(A), len(B)))
  - 综合相似度 = 0.6 × Jaccard + 0.4 × 编辑距离归一化
  - 阈值：≥ 0.75 判定为重复
  - 动作：保留来源可信度更高的那条，丢弃另一条

步骤 3：同事件合并（P1 增强）
  - 标记为"相关报道"，不合并为一条
  - 后续可在事件时间线中关联
```

**入库字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 自增主键 |
| source_id | INTEGER | 来源 ID（外键） |
| title | TEXT | 标题 |
| link | TEXT | 原文链接（唯一约束） |
| description | TEXT | 摘要/描述 |
| content | TEXT | 正文（可能为空） |
| author | TEXT | 作者 |
| pub_date | INTEGER | 发布时间（Unix 时间戳） |
| fetched_at | INTEGER | 采集时间 |
| content_type | ENUM | 'full' / 'summary_only' |
| is_read | BOOLEAN | 已读状态，默认 0 |
| is_favorite | BOOLEAN | 收藏状态，默认 0 |
| created_at | INTEGER | 入库时间 |

**验收标准**：
- [ ] 相同 link 的资讯不重复入库
- [ ] 相似度 ≥ 0.75 的标题被判定为重复
- [ ] 重复时保留来源可信度更高的条目
- [ ] 去重过程不阻塞入库（先入库再异步去重？或先查再入？需明确）

---

### 4.3 AI 质量评分

**功能描述**：对每条入库资讯进行质量评分，衡量其信息价值。

**用户故事**：
- 作为用户，我希望系统自动告诉我哪些资讯值得看，以便节省时间

**评分维度（MVP 二维）**：

| 维度 | 权重 | 说明 |
|------|------|------|
| 来源可信度 | 50% | 基于来源权威性评分（预置规则） |
| 信息密度 | 50% | 基于内容丰富度、是否有数据/引用、篇幅 |

**扩展维度（后续）**：

| 维度 | 说明 |
|------|------|
| 时效性 | 基于发布时间与当前时间差 |
| 个人相关度 | 基于用户兴趣画像匹配度 |

**评分模式**：

#### 模式一：本地规则引擎（省钱模式）

```
来源可信度（0-10）：
  - 预置来源可信度表（人工标注）
  - 未知来源默认 5 分
  - 用户可手动调整单个来源的可信度

信息密度（0-10）：
  - 基于规则打分：
    - 正文长度 > 500 字：+2
    - 正文长度 > 1500 字：+2
    - 包含数字/数据：+1
    - 包含引用/链接：+1
    - 包含图片：+1
    - 标题包含具体信息（非泛化标题）：+1
    - 包含关键词命中用户关注领域：+2
  - 上限 10 分

综合评分 = 来源可信度 × 0.5 + 信息密度 × 0.5
```

#### 模式二：LLM 评分（质量模式）

**Prompt 设计**：

```
你是一个资讯质量评估专家。请对以下资讯进行质量评分。

【资讯标题】{title}
【资讯来源】{source_name}
【资讯摘要】{description}
【资讯正文】{content 或 "无全文"}

请从以下两个维度评分（0-10 整数）：

1. 来源可信度：该来源在行业内的权威性和可靠性
2. 信息密度：内容的信息量、深度、是否有数据支撑

请严格按以下 JSON 格式返回：
{
  "source_credibility": 8,
  "information_density": 7,
  "overall_score": 7.5,
  "reason": "一句话说明评分理由"
}
```

**评分结果存储**：

| 字段 | 类型 | 说明 |
|------|------|------|
| article_id | INTEGER | 关联文章 ID |
| score_overall | REAL | 综合评分 0-10 |
| score_source | REAL | 来源可信度 0-10 |
| score_density | REAL | 信息密度 0-10 |
| score_reason | TEXT | 评分理由（LLM 模式有，本地模式为空） |
| score_mode | ENUM | 'local' / 'llm' |
| scored_at | INTEGER | 评分时间 |

**验收标准**：
- [ ] 本地模式能正确计算评分，无网络依赖
- [ ] LLM 模式能正确调用 API 并解析返回的 JSON
- [ ] LLM 返回格式异常时有降级处理（使用本地评分）
- [ ] 评分结果正确入库
- [ ] 评分耗时：本地模式 < 100ms/条，LLM 模式取决于 API

---

### 4.4 简报配置

**功能描述**：用户定义简报的生成规则，包括关注领域、数据源、国内外比例、每日总量。

**用户故事**：
- 作为用户，我希望在首次使用时配置我的偏好，以便系统按我的需求生成简报
- 作为用户，我希望随时修改配置，以便适应变化的需求

**配置项规格**：

| 配置项 | 类型 | 选项 | 默认值 |
|--------|------|------|--------|
| 关注领域 | 多选列表 | AI、区块链、教育、医疗、金融、消费科技、企业服务、硬件、游戏、政策监管 | AI |
| 数据源 | 多选列表（含预置+自定义） | 见[数据源清单](#11-数据源清单) | 全部预置源启用 |
| 国内/国际比例 | 滑块 | 0%~100%，步进 10% | 50% 国内 / 50% 国际 |
| 每日总量 | 单选 | 10 / 15 / 20 / 30 / 50 条 | 20 条 |
| 推送时间 | 时间选择器 | 任意时间 | 08:00 |

**配置生效规则**：
- 配置修改后立即生效于下次简报生成
- 已生成的历史简报不受影响
- 首次配置完成后自动触发一次简报生成

**Onboarding 流程**：

```
第①步：欢迎页，介绍产品定位
第②步：选择关注领域（多选，至少选 1 个）
第③步：配置数据源（展示预置源，可增删）
第④步：设置比例和总量
第⑤步：LLM 配置（可跳过，使用省钱模式）
第⑥步：生成第一份简报（显示进度）
```

**验收标准**：
- [ ] Onboarding 引导完整走完 6 步
- [ ] 配置项修改后正确持久化到本地存储
- [ ] 配置修改后下次简报按新规则生成
- [ ] 至少选择 1 个关注领域才能完成配置
- [ ] 配置页可从设置页随时访问

---

### 4.5 每日简报

**功能描述**：根据用户配置，自动生成或手动生成每日资讯简报。

**用户故事**：
- 作为用户，我希望每天自动收到一份简报，以便快速了解今日要闻
- 作为用户，我希望在首次配置后立即看到简报，以便验证配置效果
- 作为用户，我希望可以手动重新生成简报，以便获取最新内容

**简报生成规则**：

```
输入：
  - 用户配置（领域、来源、比例、总量）
  - 今日已采集并评分的资讯池

筛选逻辑：
  1. 按关注领域过滤（只保留命中领域的资讯）
  2. 按国内/国际比例分配名额
     - 国内名额 = 总量 × 国内比例
     - 国际名额 = 总量 × 国际比例
  3. 按综合评分降序排列
  4. 取前 N 条（N = 每日总量）

输出：
  - 简报结构（研报式）：
    - 标题：「拾光日报 · 2026-06-06」
    - 概览：今日共采集 X 条，精选 Y 条
    - 分类展示（按领域分组）
    - 每条资讯：标题 + 一句话摘要 + 评分 + 来源 + 原文链接
```

**简报结构（研报式）**：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
拾光日报 · 2026-06-06
━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 概览
今日采集 128 条，AI 精选 20 条
国内 12 条 | 国际 8 条

━━━ 🤖 人工智能（8 条）━━━

1. [9.2] OpenAI 发布 GPT-5，多模态能力大幅提升
   一句话：GPT-5 支持原生视频理解，推理能力显著增强...
   来源：TechCrunch · 2 小时前
   → 原文链接

2. [8.7] 国内大模型备案数量突破 200
   一句话：...
   来源：36氪 · 4 小时前
   → 原文链接

━━━ 💼 科技商业（5 条）━━━
...

━━━ 🔬 前沿科技（4 条）━━━
...

━━━ 📋 其他（3 条）━━━
...
```

**触发方式**：

| 触发 | 条件 | 是否推送通知 |
|------|------|-------------|
| 自动定时 | 每天到达用户设置的推送时间 | 是 |
| 手动生成 | Onboarding 完成后 | 否 |
| 手动重新生成 | 用户在简报页下拉刷新或点击重新生成 | 否 |

**生成进度状态**：

```
状态机：idle → fetching → analyzing → generating → done / error

idle：空闲
fetching：正在采集资讯（显示"正在采集..."）
analyzing：正在 AI 分析（显示"正在分析... X/Y"，显示进度）
generating：正在生成简报（显示"正在生成简报..."）
done：完成
error：失败（显示错误信息，提供重试按钮）
```

**验收标准**：
- [ ] 自动简报在设定时间生成
- [ ] Onboarding 完成后自动生成第一份简报
- [ ] 简报内容严格按用户配置的领域/来源/比例/总量筛选
- [ ] 简报按领域分组展示
- [ ] 每条资讯显示：标题、一句话摘要、评分、来源、原文链接
- [ ] 生成过程有进度状态展示
- [ ] 手动生成不发推送通知

---

### 4.6 资讯列表排序

**功能描述**：资讯列表支持按评分排序和按时间排序。

**排序规则**：

| 排序方式 | 规则 | 默认 |
|----------|------|------|
| 按评分 | 综合评分降序（高分在前） | ✅ 默认 |
| 按时间 | 发布时间降序（最新在前） | — |

**筛选规则**：

| 筛选项 | 说明 |
|--------|------|
| 全部 | 显示所有资讯 |
| 未读 | 只显示未读资讯 |
| 收藏 | 只显示收藏的资讯 |

**验收标准**：
- [ ] 默认按评分降序排列
- [ ] 可切换为按时间排序
- [ ] 筛选器支持全部/未读/收藏
- [ ] 排序和筛选可组合使用

---

### 4.7 多粒度摘要

**功能描述**：为每条资讯生成两个粒度的摘要：一句话摘要和三要点展开。

**用户故事**：
- 作为用户，我希望快速浏览一句话摘要，以便决定是否深入了解
- 作为用户，我希望展开查看三要点，以便快速了解核心内容

**摘要模式**：

#### 模式一：本地抽取式（省钱模式）

```
一句话摘要：
  - 优先使用 RSS 的 <description> 内容
  - 若 description 为空，使用 content 的前 100 字
  - 截断到 80 字以内，保证句子完整

三要点：
  - 使用 TextRank 算法提取 3 个关键句
  - 若全文不足 3 句，用已有句子填充
  - 每句限制 50 字以内
```

#### 模式二：LLM 生成式（质量模式）

**Prompt 设计**：

```
请为以下资讯生成摘要。

【资讯标题】{title}
【资讯正文】{content 或 description}

请生成：
1. 一句话摘要（不超过 80 字，概括核心信息）
2. 三个要点（每个不超过 50 字，用 bullet point 格式）

严格按以下 JSON 格式返回：
{
  "one_line": "一句话摘要内容",
  "bullets": ["要点1", "要点2", "要点3"]
}
```

**存储**：

| 字段 | 类型 | 说明 |
|------|------|------|
| article_id | INTEGER | 关联文章 ID |
| summary_one_line | TEXT | 一句话摘要 |
| summary_bullets | TEXT | 三要点（JSON 数组） |
| summary_mode | ENUM | 'local' / 'llm' |
| summarized_at | INTEGER | 生成时间 |

**验收标准**：
- [ ] 一句话摘要不超过 80 字
- [ ] 三要点每条不超过 50 字
- [ ] 本地模式无网络依赖
- [ ] LLM 模式返回格式异常时降级到本地模式
- [ ] 摘要结果正确入库

---

### 4.8 数据导出

**功能描述**：支持将资讯和简报导出为 JSON 和 Markdown 格式。

**导出类型**：

| 类型 | 范围 | 格式 |
|------|------|------|
| 单篇导出 | 当前查看的文章 | JSON / Markdown |
| 简报导出 | 当前简报的所有文章 | JSON / Markdown |
| 全量导出 | 所有数据（资讯+配置+简报+评分） | JSON（压缩包） |

**JSON 导出格式（单篇）**：

```json
{
  "id": 123,
  "title": "文章标题",
  "link": "https://example.com/article",
  "source": "TechCrunch",
  "published_at": "2026-06-06T08:00:00Z",
  "summary_one_line": "一句话摘要",
  "summary_bullets": ["要点1", "要点2", "要点3"],
  "score": {
    "overall": 8.5,
    "source_credibility": 9.0,
    "information_density": 8.0
  },
  "tags": ["AI", "大模型"],
  "content": "正文内容（如有）",
  "exported_at": "2026-06-06T10:30:00Z"
}
```

**Markdown 导出格式（单篇）**：

```markdown
# 文章标题

> 来源：TechCrunch | 发布：2026-06-06 08:00 | 评分：8.5/10

**一句话摘要**：摘要内容

**要点**：
- 要点 1
- 要点 2
- 要点 3

---

[阅读原文](https://example.com/article)

---
*导出时间：2026-06-06 10:30 | 由拾光生成*
```

**Markdown 导出格式（简报）**：

```markdown
# 拾光日报 · 2026-06-06

> 今日采集 128 条，精选 20 条 | 国内 12 条 · 国际 8 条

## 🤖 人工智能（8 条）

### 1. [9.2] OpenAI 发布 GPT-5
一句话：GPT-5 支持原生视频理解...
来源：TechCrunch · 2 小时前
[阅读原文](https://...)

### 2. [8.7] 国内大模型备案突破 200
...

## 💼 科技商业（5 条）
...

---
*由拾光生成 | 2026-06-06*
```

**全量导出**：

```
glean_export_20260606.zip
├── articles.json          # 所有文章
├── reports.json           # 所有简报
├── analysis.json          # 所有评分
├── config.json            # 用户配置
├── sources.json           # 数据源列表
└── README.md              # 导出说明
```

**导出触发**：
- 用户在文章详情页点击"导出"按钮
- 用户在简报页点击"导出简报"按钮
- 用户在设置页点击"全量导出"按钮
- 导出文件保存到手机本地存储，提供分享选项

**验收标准**：
- [ ] 单篇导出 JSON 格式正确，可被标准 JSON 解析器解析
- [ ] 单篇导出 Markdown 格式正确，可被 Markdown 渲染器正确渲染
- [ ] 简报导出包含所有文章
- [ ] 全量导出为 ZIP 压缩包，包含所有数据
- [ ] 导出文件保存到本地，提供系统分享功能

---

### 4.9 LLM 提供商配置

**功能描述**：用户配置 LLM 服务的连接信息，用于 AI 评分和摘要生成。

**用户故事**：
- 作为用户，我希望能配置自己的 API Key，以便使用 LLM 模式
- 作为用户，我希望能测试连接是否正常，以便确认配置正确

**配置项**：

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| 提供商名称 | 下拉选择 | 预置 + 自定义 | mimo / OpenAI / DeepSeek / 自定义 |
| API Key | 密码输入框 | 用户的 API Key | sk-xxx... |
| Base URL | URL 输入框 | API 端点地址 | https://api.mimo.com/v1 |
| 模型名称 | 文本输入框 | 使用的模型 ID | mimo-v2.5-pro |
| 超时时间 | 数字输入框 | API 调用超时（秒） | 30 |

**预置提供商**：

| 提供商 | Base URL | 默认模型 |
|--------|----------|----------|
| mimo | https://token-plan-cn.xiaomimimo.com/v1 | mimo-v2.5-pro |
| OpenAI | https://api.openai.com/v1 | gpt-4o-mini |
| DeepSeek | https://api.deepseek.com/v1 | deepseek-chat |
| 自定义 | 用户填写 | 用户填写 |

**连通性测试**：

```
测试逻辑：
1. 发送一个简单的测试请求（如 chat completions，内容为 "ping"）
2. 等待响应
3. 显示结果：
   - 成功："连接成功！模型：xxx，延迟：xxxms"
   - 失败：显示错误信息（API Key 无效 / 网络超时 / 模型不存在等）
```

**Onboarding 中的位置**：
- 第⑤步，位于简报配置之后、生成第一份简报之前
- 可跳过（使用省钱模式），后续在设置页随时配置

**验收标准**：
- [ ] 支持预置提供商快速选择
- [ ] 支持自定义提供商（填写 Base URL + 模型名称）
- [ ] API Key 输入框为密码模式，不显示明文
- [ ] 连通性测试能正确检测连接状态
- [ ] 配置保存后持久化到本地存储
- [ ] 省钱模式下可跳过此步骤

---

## 5. 功能规格（P1 增强）

### 5.1 文章收藏（#10）

**功能描述**：用户可收藏/取消收藏文章，有独立的收藏列表页。

**详细规则**：
- 文章卡片和详情页都有收藏按钮（心形图标）
- 点击切换收藏状态
- 收藏列表页（Tab 3）展示所有收藏文章
- 收藏文章不受数据生命周期管理清理
- 收藏状态持久化到数据库

**验收标准**：
- [ ] 文章卡片显示收藏状态
- [ ] 点击可切换收藏/取消收藏
- [ ] 收藏列表页正确展示所有收藏文章
- [ ] 收藏文章在数据清理时被保留

---

### 5.2 已读/未读状态（#11）

**功能描述**：文章自动标记已读状态，支持按未读筛选。

**详细规则**：
- 进入文章详情页自动标记为已读
- 未读文章卡片有视觉标记（如蓝色圆点）
- 资讯列表支持"只看未读"筛选
- 已读状态持久化到数据库

**验收标准**：
- [ ] 进入详情页后文章标记为已读
- [ ] 未读文章有视觉区分
- [ ] 筛选器可切换显示未读文章

---

### 5.3 评分解释面板（#12）

**功能描述**：用户点击评分数字，弹出面板展示评分依据。

**展示内容**：
- 综合评分（大字体）
- 来源可信度分数 + 简要说明
- 信息密度分数 + 简要说明
- LLM 模式下显示评分理由（score_reason）

**验收标准**：
- [ ] 点击评分弹出解释面板
- [ ] 面板展示两个维度的分数
- [ ] LLM 模式下显示评分理由
- [ ] 本地模式下显示规则说明

---

### 5.4 行动建议标签（#13）

**功能描述**：AI 为高分资讯生成行动建议标签。

**详细规则**：
- 仅对评分 ≥ 7 的资讯生成行动建议
- LLM 模式：在评分 Prompt 中追加行动建议生成
- 本地模式：基于关键词匹配生成模板化建议（如"建议关注"、"建议深入阅读"）

**行动建议 Prompt 扩展**：

```
在原有评分 Prompt 基础上追加：

5. 行动建议：针对这条资讯，读者应该采取什么行动？
   选项：立即关注 / 深入阅读 / 观望等待 / 了解即可
   用一句话说明理由。

JSON 扩展字段：
{
  ...原有字段,
  "action_tag": "深入阅读",
  "action_reason": "该技术突破可能影响行业格局"
}
```

**验收标准**：
- [ ] 评分 ≥ 7 的资讯有行动建议标签
- [ ] 标签类型：立即关注 / 深入阅读 / 观望等待 / 了解即可
- [ ] LLM 模式显示 AI 生成的理由
- [ ] 本地模式显示模板化建议

---

### 5.5 RSS Feed 输出（#14）

**功能描述**：将高分资讯输出为标准 RSS Feed，供其他应用订阅。

**详细规则**：
- 生成标准 RSS 2.0 XML
- 包含评分 ≥ 用户设定阈值的资讯（默认 ≥ 7）
- 每次生成简报时更新 Feed
- Feed URL 为本地文件路径，可通过分享功能发送

**RSS 结构**：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>拾光精选</title>
    <description>AI 精选的高质量资讯</description>
    <lastBuildDate>RFC 2822 格式时间</lastBuildDate>
    <item>
      <title>文章标题</title>
      <link>原文链接</link>
      <description>一句话摘要</description>
      <pubDate>发布时间</pubDate>
      <category>领域标签</category>
    </item>
    ...
  </channel>
</rss>
```

**验收标准**：
- [ ] 生成的 RSS XML 符合 RSS 2.0 规范
- [ ] 只包含评分 ≥ 阈值的资讯
- [ ] 可被标准 RSS 阅读器解析

---

### 5.6 数据生命周期管理（#15）

**功能描述**：用户可配置本地数据保留天数，超期数据自动清理，清理前提醒导出。

**详细规则**：
- 默认保留 30 天，可配置（7/14/30/60/90/永久）
- 清理前 24 小时推送提醒："有 X 条数据即将过期，是否导出？"
- 收藏文章不参与自动清理
- 清理范围：文章 + 评分 + 摘要 + 简报

**验收标准**：
- [ ] 超过保留天数的非收藏文章被清理
- [ ] 清理前推送提醒
- [ ] 用户可选择导出后再清理
- [ ] 收藏文章不受影响

---

### 5.7 AI 运行模式管理（#16）

**功能描述**：统一管理 AI 评分和摘要的运行模式，含成本监控。

**三种模式**：

| 模式 | 评分 | 摘要 | 成本 | 质量 |
|------|------|------|------|------|
| 省钱模式 | 本地规则 | 抽取式 | 零 | ⭐⭐⭐ |
| 质量模式 | LLM API | LLM 生成式 | 按量计费 | ⭐⭐⭐⭐⭐ |
| 混合模式（推荐） | 本地规则 | LLM 生成式 | 低 | ⭐⭐⭐⭐ |

**成本监控**：
- 记录每次 LLM API 调用的 token 消耗
- 按日/周/月统计成本
- 可设置预算上限（如每月 ¥10）
- 达到预算上限自动切换到省钱模式并提醒

**验收标准**：
- [ ] 三种模式可切换
- [ ] 切换后立即生效
- [ ] 成本统计准确
- [ ] 预算上限触发时自动降级并提醒

---

### 5.8 兴趣画像（#17）

**功能描述**：基于用户阅读历史自动构建兴趣画像，展示信息消费结构。

**详细规则**：
- 统计用户已读文章的领域分布
- 生成兴趣雷达图或饼图
- 展示消费结构：如"本周 AI 类文章占 60%，科技商业占 25%"
- 需要积累至少 50 篇已读数据才生成画像

**验收标准**：
- [ ] 基于已读文章统计领域分布
- [ ] 可视化展示消费结构
- [ ] 数据不足时显示提示

---

### 5.9 用户反馈闭环（#18）

**功能描述**：用户可标记文章"有用/没用"，反向优化评分模型。

**详细规则**：
- 文章详情页底部有"有用👍"和"没用👎"按钮
- 反馈记录入库，用于调整来源可信度权重
- 长期：多次标记某来源"没用"，自动降低该来源可信度

**验收标准**：
- [ ] 文章详情页有反馈按钮
- [ ] 反馈记录正确入库
- [ ] 反馈数据可被评分模型使用

---

### 5.10 事件时间线（#19）

**功能描述**：同一事件的后续报道自动关联，形成时间线。

**关联逻辑**：
- 基于标题相似度 + 来源 + 时间窗口（7 天内）
- 相似度 ≥ 0.6 的文章标记为"相关报道"
- 在文章详情页展示"相关报道"列表，按时间排序

**验收标准**：
- [ ] 相关文章自动关联
- [ ] 详情页展示时间线
- [ ] 时间线按时间排序

---

### 5.11 数据源冗余与降级（#20）

**功能描述**：单源中断时自动切换备用源，失效提醒用户。

**详细规则**：
- 连续 3 次采集失败，标记源为"异常"
- 异常源自动禁用，推送通知提醒用户
- 用户可手动重新启用

**验收标准**：
- [ ] 连续失败自动标记异常
- [ ] 推送通知提醒
- [ ] 用户可手动恢复

---

### 5.12 采集频率与网络策略（#21）

**功能描述**：可配置采集间隔和网络策略，控制电量和流量消耗。

**配置项**：

| 配置项 | 选项 | 默认 |
|--------|------|------|
| 采集间隔 | 1h / 2h / 4h / 手动 | 2h |
| 网络策略 | 仅 WiFi / WiFi + 移动数据 | 仅 WiFi |
| 后台采集 | 开启 / 关闭 | 开启 |

**验收标准**：
- [ ] 配置修改后立即生效
- [ ] 仅 WiFi 模式下移动数据不触发采集
- [ ] 手动模式下只在打开 App 时采集

---

### 5.13 正文抓取降级（#22）

**功能描述**：RSS 无全文时尝试抓取网页正文，失败则标记"仅摘要"。

**抓取流程**：

```
1. 检查 RSS 条目是否有 content:encoded 且长度 > 200 字
   → 有：标记 content_type = 'full'，使用该内容
   → 无：进入步骤 2

2. 使用 Dio 请求原文链接
   → 成功：使用 readability 解析提取正文
     → 解析成功：标记 content_type = 'full'
     → 解析失败：标记 content_type = 'summary_only'
   → 失败（超时/403等）：标记 content_type = 'summary_only'

3. content_type = 'summary_only' 的文章在 UI 上标注"仅摘要"
```

**验收标准**：
- [ ] 有全文 RSS 时正确提取
- [ ] 无全文时尝试网页抓取
- [ ] 抓取失败不影响入库
- [ ] UI 上标注"仅摘要"的文章

---

### 5.14 执行记录（#23）

**功能描述**：记录采集、评分、简报生成的执行日志，用户可查看。

**日志内容**：

| 字段 | 说明 |
|------|------|
| 时间 | 执行时间 |
| 类型 | 采集 / 评分 / 简报生成 |
| 状态 | 成功 / 失败 |
| 详情 | 成功数/失败数/耗时/错误信息 |

**展示**：设置页 → 执行记录，按时间倒序，最多保留 100 条。

**验收标准**：
- [ ] 每次采集/评分/生成都记录日志
- [ ] 日志按时间倒序展示
- [ ] 错误日志有详细错误信息

---

### 5.15 本地模型引导下载（#24）

**功能描述**：首次使用语义搜索等需要 embedding 的功能时引导下载模型。

**详细规则**：
- 触发条件：用户首次使用 P3 语义搜索功能
- 模型：bge-m3（约 300-500MB）
- 展示：下载进度条 + 存储占用
- 不阻塞 LLM 模式使用

**验收标准**：
- [ ] 首次使用时弹出引导
- [ ] 显示下载进度
- [ ] 下载完成后自动启用
- [ ] 不影响 LLM 模式正常使用

---

## 6. 功能规格（P2/P3 远期）

### P2 — V2 差异化

| # | 功能 | 核心逻辑 |
|---|------|----------|
| 25 | Webhook 推送 | 高分文章（≥ 阈值）自动 POST 到用户配置的 Webhook URL（微信/飞书/Telegram Bot API） |
| 26 | 一键待办同步 | 行动建议标签 → 调用 Todoist/滴答清单 API 创建任务 |
| 27 | 关注/忽略领域 | 用户显式标记"关注"和"忽略"，评分公式加入偏好因子 |
| 28 | 探索推荐 + 茧房预警 | 每周推送 5 条舒适区外内容；消费过于集中（>70% 同一领域）时提醒 |
| 29 | REST API | 暴露 /articles, /reports, /scores 端点，支持 JSON 响应 |
| 30 | 自定义导出模板 | 用户自定义 Markdown 导出模板（变量替换） |

### P3 — V3 长期价值

| # | 功能 | 核心逻辑 |
|---|------|----------|
| 31 | 语义搜索 | 基于 embedding 的余弦相似度搜索，需要本地 bge-m3 模型 |
| 32 | 问答式检索 | 用户输入自然语言问题 → 检索相关文章 → LLM 合成答案 |
| 33 | 实体识别与卡片 | NER 提取人名/组织/地点/事件，点击实体查看相关资讯 |
| 34 | 阅读笔记 | 文章内标注高亮，笔记关联原文，本地存储 |
| 35 | 事件演化追踪 | 事件时间线的深化版，长期追踪事件发展脉络 |

---

## 7. 数据模型

### 7.1 ER 关系图

```
sources (数据源)
  ├── 1:N ── articles (文章)
  │           ├── 1:1 ── analysis (评分)
  │           ├── 1:1 ── summaries (摘要)
  │           ├── 1:N ── article_tags (标签)
  │           ├── N:M ── report_items (简报条目)
  │           └── 1:N ── user_feedback (用户反馈)
  │
  └── 1:N ── source_errors (采集错误)

reports (简报)
  └── 1:N ── report_items (简报条目)

user_config (用户配置)
└── 单表，key-value 结构
```

### 7.2 完整建表 SQL

```sql
-- ========================================
-- 数据源
-- ========================================
CREATE TABLE sources (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  url           TEXT NOT NULL UNIQUE,
  type          TEXT NOT NULL DEFAULT 'rss',  -- 'rss' / 'atom' / 'api'
  category      TEXT,                          -- 领域标签
  is_domestic   INTEGER NOT NULL DEFAULT 1,    -- 1=国内 0=国际
  credibility   REAL NOT NULL DEFAULT 5.0,     -- 来源可信度 0-10
  enabled       INTEGER NOT NULL DEFAULT 1,    -- 启用状态
  status        TEXT NOT NULL DEFAULT 'active', -- 'active' / 'error' / 'disabled'
  last_fetched_at INTEGER,                     -- 最后采集时间
  error_count   INTEGER NOT NULL DEFAULT 0,    -- 连续失败次数
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- ========================================
-- 文章
-- ========================================
CREATE TABLE articles (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id     INTEGER NOT NULL REFERENCES sources(id),
  title         TEXT NOT NULL,
  link          TEXT NOT NULL UNIQUE,
  description   TEXT,
  content       TEXT,
  author        TEXT,
  pub_date      INTEGER,                       -- Unix 时间戳
  fetched_at    INTEGER NOT NULL,
  content_type  TEXT NOT NULL DEFAULT 'summary_only', -- 'full' / 'summary_only'
  is_read       INTEGER NOT NULL DEFAULT 0,
  is_favorite   INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL
);

CREATE INDEX idx_articles_source ON articles(source_id);
CREATE INDEX idx_articles_pub_date ON articles(pub_date DESC);
CREATE INDEX idx_articles_score ON articles(id DESC);

-- ========================================
-- AI 评分
-- ========================================
CREATE TABLE analysis (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id    INTEGER NOT NULL UNIQUE REFERENCES articles(id),
  score_overall REAL NOT NULL,
  score_source  REAL NOT NULL,
  score_density REAL NOT NULL,
  score_reason  TEXT,
  score_mode    TEXT NOT NULL,                  -- 'local' / 'llm'
  scored_at     INTEGER NOT NULL
);

CREATE INDEX idx_analysis_score ON analysis(score_overall DESC);

-- ========================================
-- 摘要
-- ========================================
CREATE TABLE summaries (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id      INTEGER NOT NULL UNIQUE REFERENCES articles(id),
  summary_one_line TEXT,
  summary_bullets  TEXT,                        -- JSON 数组
  summary_mode    TEXT NOT NULL,                -- 'local' / 'llm'
  summarized_at   INTEGER NOT NULL
);

-- ========================================
-- 标签
-- ========================================
CREATE TABLE article_tags (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id    INTEGER NOT NULL REFERENCES articles(id),
  tag           TEXT NOT NULL,
  UNIQUE(article_id, tag)
);

CREATE INDEX idx_tags_article ON article_tags(article_id);
CREATE INDEX idx_tags_tag ON article_tags(tag);

-- ========================================
-- 简报
-- ========================================
CREATE TABLE reports (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  date              TEXT NOT NULL,              -- 'YYYY-MM-DD'
  title             TEXT NOT NULL,              -- '拾光日报 · 2026-06-06'
  total_fetched     INTEGER NOT NULL,           -- 采集总数
  total_selected    INTEGER NOT NULL,           -- 精选数
  domestic_count    INTEGER NOT NULL,
  international_count INTEGER NOT NULL,
  trigger_type      TEXT NOT NULL,              -- 'auto' / 'manual'
  created_at        INTEGER NOT NULL,
  UNIQUE(date, trigger_type)
);

-- ========================================
-- 简报条目
-- ========================================
CREATE TABLE report_items (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  report_id     INTEGER NOT NULL REFERENCES reports(id),
  article_id    INTEGER NOT NULL REFERENCES articles(id),
  position      INTEGER NOT NULL,              -- 排序位置
  category      TEXT,                           -- 所属领域分组
  UNIQUE(report_id, article_id)
);

CREATE INDEX idx_report_items_report ON report_items(report_id);

-- ========================================
-- 用户配置
-- ========================================
CREATE TABLE user_config (
  key           TEXT PRIMARY KEY,
  value         TEXT NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- ========================================
-- 用户反馈
-- ========================================
CREATE TABLE user_feedback (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id    INTEGER NOT NULL REFERENCES articles(id),
  feedback_type TEXT NOT NULL,                  -- 'useful' / 'not_useful'
  created_at    INTEGER NOT NULL
);

CREATE INDEX idx_feedback_article ON user_feedback(article_id);

-- ========================================
-- 采集错误日志
-- ========================================
CREATE TABLE source_errors (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id     INTEGER NOT NULL REFERENCES sources(id),
  error_message TEXT NOT NULL,
  http_status   INTEGER,
  created_at    INTEGER NOT NULL
);

-- ========================================
-- 执行日志
-- ========================================
CREATE TABLE execution_logs (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  type          TEXT NOT NULL,                  -- 'fetch' / 'score' / 'generate'
  status        TEXT NOT NULL,                  -- 'success' / 'error'
  detail        TEXT,                           -- JSON 格式详情
  duration_ms   INTEGER,
  created_at    INTEGER NOT NULL
);

CREATE INDEX idx_logs_type ON execution_logs(type, created_at DESC);

-- ========================================
-- LLM 成本记录
-- ========================================
CREATE TABLE llm_costs (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  operation     TEXT NOT NULL,                  -- 'score' / 'summary' / 'action'
  model         TEXT NOT NULL,
  input_tokens  INTEGER NOT NULL,
  output_tokens INTEGER NOT NULL,
  cost_usd      REAL,
  created_at    INTEGER NOT NULL
);

CREATE INDEX idx_costs_date ON llm_costs(created_at);
```

### 7.3 用户配置 key 定义

| key | value 格式 | 说明 |
|-----|-----------|------|
| `onboarding_completed` | `true` / `false` | 是否完成 Onboarding |
| `focus_domains` | `["AI","区块链"]` | 关注领域 |
| `domestic_ratio` | `0.5` | 国内比例 0-1 |
| `daily_count` | `20` | 每日总量 |
| `push_time` | `08:00` | 推送时间 |
| `ai_mode` | `local` / `llm` / `hybrid` | AI 模式 |
| `llm_provider` | `mimo` | LLM 提供商 |
| `llm_api_key` | `sk-xxx` | API Key（加密存储） |
| `llm_base_url` | `https://...` | Base URL |
| `llm_model` | `mimo-v2.5-pro` | 模型名称 |
| `llm_timeout` | `30` | 超时秒数 |
| `llm_budget_monthly` | `10.0` | 月度预算（元） |
| `fetch_interval_hours` | `2` | 采集间隔 |
| `network_policy` | `wifi_only` / `all` | 网络策略 |
| `background_fetch` | `true` / `false` | 后台采集 |
| `retention_days` | `30` | 数据保留天数 |
| `rss_score_threshold` | `7.0` | RSS 输出评分阈值 |
| `sort_by` | `score` / `time` | 默认排序方式 |

---

## 8. AI 引擎设计

### 8.1 AI 处理流水线

```
文章入库
  ↓
┌─────────────────────────────┐
│       AI 处理流水线          │
│                             │
│  Step 1: 质量评分            │
│    ├─ 本地模式：规则引擎      │
│    └─ LLM 模式：API 调用     │
│                             │
│  Step 2: 摘要生成            │
│    ├─ 本地模式：抽取式        │
│    └─ LLM 模式：生成式        │
│                             │
│  Step 3: 标签提取            │
│    └─ 关键词匹配             │
│                             │
│  Step 4: 行动建议（P1）       │
│    └─ LLM 生成               │
└─────────────────────────────┘
  ↓
结果入库
```

### 8.2 本地评分规则引擎

```python
# 伪代码：本地评分

def local_score(article, source):
    # 来源可信度：直接使用预置值
    score_source = source.credibility  # 0-10
    
    # 信息密度：基于规则打分
    score_density = 0
    content = article.content or article.description or ""
    
    if len(content) > 500:
        score_density += 2
    if len(content) > 1500:
        score_density += 2
    if has_numbers(content):       # 包含数字/数据
        score_density += 1
    if has_links(content):         # 包含引用/链接
        score_density += 1
    if has_images(content):        # 包含图片
        score_density += 1
    if is_specific_title(article.title):  # 标题具体非泛化
        score_density += 1
    if matches_focus_domains(article):    # 命中关注领域
        score_density += 2
    
    score_density = min(score_density, 10)
    
    # 综合评分
    score_overall = score_source * 0.5 + score_density * 0.5
    
    return {
        "score_overall": round(score_overall, 1),
        "score_source": round(score_source, 1),
        "score_density": round(score_density, 1),
        "score_mode": "local"
    }
```

### 8.3 本地摘要抽取

```python
# 伪代码：本地摘要

def local_summarize(article):
    content = article.content or article.description or ""
    
    # 一句话摘要
    if article.description and len(article.description) <= 80:
        one_line = article.description
    else:
        # 取 content 前 100 字，截断到最后一个完整句
        one_line = truncate_to_sentence(content, max_len=80)
    
    # 三要点：TextRank 提取
    sentences = split_sentences(content)
    if len(sentences) >= 3:
        ranked = textrank(sentences, top_k=3)
        bullets = [truncate(s, 50) for s in ranked]
    else:
        bullets = [truncate(s, 50) for s in sentences]
        while len(bullets) < 3:
            bullets.append("")
    
    return {
        "summary_one_line": one_line,
        "summary_bullets": bullets,
        "summary_mode": "local"
    }
```

### 8.4 LLM Prompt 完整模板

```
你是一个资讯质量评估和摘要生成专家。

请对以下资讯完成三项任务：

【资讯标题】{title}
【资讯来源】{source_name}
【资讯摘要】{description}
【资讯正文】{content 或 "无全文"}

任务 1：质量评分
从以下两个维度评分（0-10 整数）：
- 来源可信度：该来源在行业内的权威性和可靠性
- 信息密度：内容的信息量、深度、是否有数据支撑

任务 2：摘要生成
- 一句话摘要（不超过 80 字，概括核心信息）
- 三个要点（每个不超过 50 字）

任务 3：行动建议（仅当综合评分 ≥ 7 时）
- 行动标签：立即关注 / 深入阅读 / 观望等待 / 了解即可
- 一句话理由

严格按以下 JSON 格式返回：
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

### 8.5 LLM 调用策略

| 策略 | 规则 |
|------|------|
| 批量处理 | 每次最多 5 条文章合并为一个 Prompt（节省 token） |
| 重试 | 失败重试 2 次，间隔 5/15 秒 |
| 降级 | LLM 失败自动降级到本地模式 |
| 限流 | 每分钟最多 10 次 API 调用 |
| 成本控制 | 每次调用记录 token 消耗，超预算自动降级 |

---

## 9. 技术架构

### 9.1 系统架构

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│                                                     │
│  ┌─────────────┐  ┌──────────────────────────────┐  │
│  │   表现层     │  │         业务逻辑层            │  │
│  │             │  │                              │  │
│  │ · Pages     │  │ · 采集服务 (FetchService)     │  │
│  │ · Widgets   │  │ · 评分服务 (ScoreService)     │  │
│  │ · Providers │  │ · 摘要服务 (SummaryService)   │  │
│  │             │  │ · 简报服务 (ReportService)    │  │
│  └─────────────┘  │ · 导出服务 (ExportService)    │  │
│                    │ · 配置服务 (ConfigService)    │  │
│                    └──────────┬───────────────────┘  │
│                               │                      │
│  ┌────────────────────────────┴───────────────────┐  │
│  │                 数据层                          │  │
│  │                                                │  │
│  │ · SQLite (sqflite)                             │  │
│  │ · Repository Pattern                           │  │
│  │ · DAO: ArticleDao, ReportDao, AnalysisDao...   │  │
│  └────────────────────────────────────────────────┘  │
│                                                     │
│  ┌────────────────────────────────────────────────┐  │
│  │              基础设施层                         │  │
│  │                                                │  │
│  │ · Dio (HTTP) · RSS Parser                      │  │
│  │ · WorkManager (Android 后台)                    │  │
│  │ · flutter_local_notifications                  │  │
│  │ · path_provider · share_plus                   │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
         │                          │
         ↓                          ↓
   RSS 源站 (采集)            LLM API (AI 分析)
```

### 9.2 目录结构

```
lib/
├── main.dart
├── app.dart                          # App 入口、路由、主题
│
├── config/
│   ├── constants.dart                # 常量定义
│   ├── theme.dart                    # 主题配置
│   └── routes.dart                   # 路由定义
│
├── models/                           # 数据模型
│   ├── article.dart
│   ├── source.dart
│   ├── report.dart
│   ├── analysis.dart
│   ├── summary.dart
│   ├── user_config.dart
│   └── execution_log.dart
│
├── database/                         # 数据库层
│   ├── database_helper.dart          # SQLite 初始化、迁移
│   ├── dao/
│   │   ├── article_dao.dart
│   │   ├── source_dao.dart
│   │   ├── report_dao.dart
│   │   ├── analysis_dao.dart
│   │   ├── summary_dao.dart
│   │   └── config_dao.dart
│   └── migrations/
│       └── v1_initial.dart
│
├── services/                         # 业务服务
│   ├── fetch_service.dart            # RSS 采集
│   ├── score_service.dart            # AI 评分
│   ├── summary_service.dart          # AI 摘要
│   ├── report_service.dart           # 简报生成
│   ├── export_service.dart           # 数据导出
│   ├── config_service.dart           # 配置管理
│   ├── dedup_service.dart            # 去重服务
│   ├── notification_service.dart     # 通知服务
│   └── scheduler_service.dart        # 定时任务
│
├── providers/                        # Riverpod 状态管理
│   ├── article_provider.dart
│   ├── report_provider.dart
│   ├── config_provider.dart
│   └── fetch_status_provider.dart
│
├── pages/                            # 页面
│   ├── home/
│   │   ├── home_page.dart
│   │   ├── article_list.dart
│   │   ├── article_card.dart
│   │   └── filter_bar.dart
│   ├── report/
│   │   ├── report_page.dart
│   │   ├── report_detail.dart
│   │   └── report_history.dart
│   ├── favorites/
│   │   └── favorites_page.dart
│   ├── article_detail/
│   │   └── article_detail_page.dart
│   ├── settings/
│   │   ├── settings_page.dart
│   │   ├── report_config_page.dart
│   │   ├── source_manage_page.dart
│   │   ├── ai_mode_page.dart
│   │   ├── llm_config_page.dart
│   │   ├── data_manage_page.dart
│   │   ├── fetch_settings_page.dart
│   │   └── execution_log_page.dart
│   └── onboarding/
│       ├── onboarding_page.dart
│       ├── step_welcome.dart
│       ├── step_domains.dart
│       ├── step_sources.dart
│       ├── step_ratio.dart
│       ├── step_llm.dart
│       └── step_generate.dart
│
├── widgets/                          # 通用组件
│   ├── score_badge.dart              # 评分徽章
│   ├── summary_card.dart             # 摘要卡片
│   ├── source_chip.dart              # 来源标签
│   ├── progress_indicator.dart       # 进度指示器
│   ├── empty_state.dart              # 空状态
│   └── error_state.dart              # 错误状态
│
├── utils/                            # 工具类
│   ├── dedup.dart                    # 去重算法
│   ├── textrank.dart                 # TextRank 算法
│   ├── date_utils.dart               # 日期工具
│   ├── rss_parser.dart               # RSS/Atom 解析
│   └── readability.dart              # 网页正文提取
│
└── l10n/                             # 国际化（可选）
    ├── app_zh.arb
    └── app_en.arb
```

### 9.3 依赖清单

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.5.0
  
  # 数据库
  sqflite: ^2.3.0
  path: ^1.8.0
  
  # 网络
  dio: ^5.4.0
  
  # RSS 解析
  webfeed: ^1.0.0    # 或 xml: ^6.0.0 手动解析
  
  # 后台任务
  workmanager: ^0.5.0
  
  # 本地通知
  flutter_local_notifications: ^17.0.0
  
  # 文件路径
  path_provider: ^2.1.0
  
  # 分享
  share_plus: ^9.0.0
  
  # 压缩（全量导出）
  archive: ^3.4.0
  
  # JSON
  json_annotation: ^4.8.0
  
  # 日期格式化
  intl: ^0.19.0
  
  # 加密（API Key 存储）
  flutter_secure_storage: ^9.0.0
  
  # HTML 解析（正文提取）
  html: ^0.15.0
  
  # URL launch
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  flutter_lints: ^4.0.0
```

---

## 10. UI/UX 流程

### 10.1 首次启动流程

```
启动 App
  ↓
检查 onboarding_completed 配置
  ├─ false → 进入 Onboarding
  │           ↓
  │         ① 欢迎页
  │         ② 选择关注领域
  │         ③ 配置数据源
  │         ④ 设置比例和总量
  │         ⑤ LLM 配置（可跳过）
  │         ⑥ 生成第一份简报（进度页）
  │           ↓
  │         进入首页
  │
  └─ true → 直接进入首页
```

### 10.2 首页交互

```
首页
├── 顶部：今日简报卡片（摘要 + "查看详情"按钮）
├── 中间：筛选器（全部 / 未读 / 收藏）+ 排序切换
└── 列表：资讯卡片流
      ├── 每张卡片：
      │   ├── 左侧：评分徽章
      │   ├── 中间：标题 + 一句话摘要 + 来源 + 时间
      │   ├── 右侧：收藏按钮
      │   └── 底部：标签
      │
      └── 点击卡片 → 资讯详情页
            ├── 标题
            ├── 来源 + 时间 + 评分
            ├── 一句话摘要（默认展开）
            ├── 三要点（点击展开）
            ├── 行动建议标签（P1）
            ├── 评分解释面板（P1，点击评分弹出）
            ├── 原文链接按钮
            ├── 收藏按钮
            └── 导出按钮
```

### 10.3 简报页交互

```
简报页（Tab 2）
├── 今日简报（默认展示）
│   ├── 概览：采集数 / 精选数 / 国内外分布
│   ├── 分组列表：按领域分组
│   │   └── 每条：评分 + 标题 + 一句话摘要 + 来源
│   └── 底部操作：导出简报 / 重新生成
│
└── 历史简报
    ├── 列表：按日期倒序
    └── 点击 → 简报详情（同今日简报结构）
```

### 10.4 设置页交互

```
设置页（Tab 4）
├── 简报配置
│   ├── 关注领域（多选）
│   ├── 数据源管理（列表 + 添加按钮）
│   ├── 国内/国际比例（滑块）
│   └── 每日总量（单选）
│
├── AI 设置
│   ├── AI 模式切换（省钱/质量/混合）
│   ├── LLM 提供商配置
│   │   ├── 提供商选择
│   │   ├── API Key
│   │   ├── Base URL
│   │   ├── 模型名称
│   │   └── 连通性测试按钮
│   └── 成本监控（本月消耗 / 预算上限）
│
├── 数据管理
│   ├── 存储占用（饼图/数字）
│   ├── 数据导出（单篇/简报/全量）
│   ├── 数据保留天数
│   └── 手动清理
│
├── 采集设置
│   ├── 采集间隔
│   ├── 网络策略
│   └── 后台采集开关
│
└── 执行记录
    └── 日志列表（按时间倒序）
```

---

## 11. 数据源清单

### 11.1 预置国内源

| 名称 | URL | 领域 | 可信度 |
|------|-----|------|--------|
| 量子位 | https://www.qbitai.com/feed | AI | 8.0 |
| 36氪 | https://36kr.com/feed | 科技商业 | 7.5 |
| InfoQ | https://www.infoq.cn/feed | 技术 | 8.0 |
| 爱范儿 | https://www.ifanr.com/feed | 消费科技 | 7.0 |
| 少数派 | https://sspai.com/feed | 效率工具 | 7.5 |
| IT之家 | https://www.ithome.com/rss | 综合科技 | 6.5 |
| 机器之心 | https://www.jiqizhixin.com/rss | AI | 8.0 |
| 虎嗅 | https://www.huxiu.com/rss/0.xml | 科技商业 | 7.0 |

### 11.2 预置国际源

| 名称 | URL | 领域 | 可信度 |
|------|-----|------|--------|
| TechCrunch | https://techcrunch.com/feed | 科技商业 | 9.0 |
| The Verge | https://www.theverge.com/rss/index.xml | 消费科技 | 8.5 |
| Hacker News | https://hnrss.org/frontpage | 技术社区 | 7.5 |
| Ars Technica | https://feeds.arstechnica.com/arstechnica/index | 深度技术 | 8.5 |
| MIT Tech Review | https://www.technologyreview.com/feed | 前沿科技 | 9.0 |
| Wired | https://www.wired.com/feed/rss | 科技文化 | 8.0 |
| OpenAI Blog | https://openai.com/blog/rss.xml | AI | 9.0 |
| Google AI Blog | https://blog.google/technology/ai/rss | AI | 9.0 |

### 11.3 领域分类定义

| 领域 | 关键词（用于本地模式匹配） |
|------|--------------------------|
| AI | AI, 人工智能, 大模型, LLM, GPT, 机器学习, 深度学习, AIGC, AGI |
| 区块链 | 区块链, Web3, 加密, 比特币, 以太坊, DeFi, NFT |
| 教育 | 教育, EdTech, 在线学习, MOOC, 智慧教育 |
| 医疗 | 医疗, 医药, 生物科技, 基因, 健康科技 |
| 金融 | 金融, FinTech, 投资, 融资, IPO, 银行 |
| 消费科技 | 手机, 智能硬件, IoT, 可穿戴, 新能源车 |
| 企业服务 | SaaS, 云计算, 企业服务, 数字化转型 |
| 硬件 | 芯片, 半导体, GPU, CPU, 量子计算 |
| 游戏 | 游戏, 元宇宙, VR, AR, XR |
| 政策监管 | 政策, 监管, 反垄断, 数据安全, 隐私 |

---

## 12. 配置默认值

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| 关注领域 | `["AI"]` | 默认只关注 AI |
| 数据源 | 全部预置源启用 | 16 个源 |
| 国内比例 | `0.5` | 50/50 |
| 每日总量 | `20` | 20 条 |
| 推送时间 | `08:00` | 早上 8 点 |
| AI 模式 | `hybrid` | 混合模式（推荐） |
| LLM 提供商 | `mimo` | 默认 mimo |
| LLM 超时 | `30` 秒 | — |
| 月度预算 | `10.0` 元 | — |
| 采集间隔 | `2` 小时 | — |
| 网络策略 | `wifi_only` | 仅 WiFi |
| 后台采集 | `true` | 开启 |
| 数据保留 | `30` 天 | — |
| RSS 阈值 | `7.0` | 评分 ≥ 7 输出 RSS |
| 默认排序 | `score` | 按评分 |

---

## 13. 错误处理与边界情况

### 13.1 网络错误

| 场景 | 处理 |
|------|------|
| 无网络连接 | 跳过采集，显示"离线模式"提示，使用本地缓存数据 |
| RSS 源超时 | 重试 3 次（5s/15s/30s），失败记录日志 |
| LLM API 超时 | 重试 2 次（5s/15s），失败降级到本地模式 |
| LLM API 返回格式错误 | 重试 1 次，失败降级到本地模式 |
| LLM API 余额不足 | 立即降级到省钱模式，推送通知 |

### 13.2 数据错误

| 场景 | 处理 |
|------|------|
| RSS XML 格式错误 | 跳过该条目，记录错误 |
| 文章 title 为空 | 使用 "无标题" 占位 |
| 文章 link 为空 | 跳过，不入库 |
| pub_date 格式异常 | 使用 fetched_at 替代 |
| 数据库写入失败 | 重试 1 次，失败记录错误日志 |

### 13.3 UI 边界

| 场景 | 处理 |
|------|------|
| 无资讯可显示 | 空状态页面："暂无资讯，试试添加更多数据源" |
| 简报生成失败 | 错误页面 + 重试按钮 |
| 首次使用无数据 | 引导完成 Onboarding |
| 导出文件过大（>50MB） | 提示用户确认 |
| 存储空间不足 | 提示清理数据或导出后清理 |

### 13.4 并发与竞态

| 场景 | 处理 |
|------|------|
| 采集过程中用户修改配置 | 本次采集使用旧配置，下次生效 |
| 手动触发与自动触发冲突 | 加锁，拒绝重复触发，提示"正在生成中" |
| 多页面同时读写数据库 | SQLite WAL 模式，支持并发读 |

---

## 14. 性能要求

| 指标 | 要求 |
|------|------|
| App 启动时间 | < 2 秒（冷启动） |
| 首页加载 | < 500ms（本地数据） |
| 资讯列表滚动 | 60fps，无卡顿 |
| 本地评分速度 | < 100ms/条 |
| LLM 评分速度 | 取决于 API，UI 显示进度 |
| 简报生成（20 条） | < 5 秒（本地模式）/ < 30 秒（LLM 模式） |
| 搜索响应（P3） | < 300ms（本地向量搜索） |
| 数据库查询 | < 50ms（单表 < 10 万条） |
| 内存占用 | < 150MB |
| 安装包大小 | < 30MB（不含本地模型） |

---

## 15. 安全与隐私

### 15.1 数据安全

| 措施 | 说明 |
|------|------|
| API Key 存储 | 使用 flutter_secure_storage 加密存储 |
| 本地数据库 | SQLite 文件存储在 App 私有目录，其他 App 无法访问 |
| 网络传输 | HTTPS only，证书校验 |
| 导出文件 | 存储在 App 私有目录，用户主动分享 |

### 15.2 隐私原则

- **不收集用户行为数据**（除非用户开启反馈闭环）
- **不上传任何数据到第三方**（除 LLM API 调用外）
- **LLM 调用不包含用户身份信息**，只发送文章内容
- **所有数据本地存储**，用户完全控制

---

## 16. 验收标准

### 16.1 MVP 验收清单

**采集链路**：
- [ ] 能成功采集预置 RSS 源
- [ ] 能添加自定义 RSS 源
- [ ] 去重算法正确（Jaccard + 编辑距离）
- [ ] 采集失败不影响其他源

**AI 分析**：
- [ ] 本地模式能正确评分（规则引擎）
- [ ] LLM 模式能正确调用 API 评分
- [ ] 本地模式能正确生成摘要（抽取式）
- [ ] LLM 模式能正确生成摘要（生成式）
- [ ] LLM 失败时自动降级到本地模式

**简报生成**：
- [ ] 按用户配置的领域/来源/比例/总量筛选
- [ ] 简报按领域分组展示
- [ ] 手动生成和自动生成都正常工作
- [ ] 生成过程有进度状态展示

**配置系统**：
- [ ] Onboarding 引导完整走完
- [ ] 配置修改后立即生效
- [ ] LLM 连通性测试正常

**数据导出**：
- [ ] JSON 格式正确可解析
- [ ] Markdown 格式正确可渲染
- [ ] 全量导出为 ZIP 包

**基础交互**：
- [ ] 资讯列表按评分/时间排序
- [ ] 筛选器（全部/未读/收藏）工作正常
- [ ] 资讯详情页展示完整信息
- [ ] 原文链接可跳转

---

*文档版本：v1.0*
*创建日期：2026-06-06*
*项目名称：拾光 / Glean*
*用途：AI Agent 开发支撑文档*
