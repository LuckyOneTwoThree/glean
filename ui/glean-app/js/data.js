// Mock Data Layer for Glean App
const GleanData = {
    // User Configuration
    userConfig: {
        categories: ['科技', '商业'],
        dailyCount: 20,
        domesticRatio: 0.6,
        pushTime: '08:00',
        aiMode: 'hybrid',
        fetchInterval: 2,
        wifiOnly: false,
        retentionDays: 30,
        onboardingDone: false,
    },

    // LLM Configuration
    llmConfig: {
        provider: 'mimo',
        apiKey: '',
        model: 'gpt-4o',
        baseUrl: 'https://api.openai.com/v1',
        timeout: 30,
        isConfigured: false,
    },

    // Feeds (Data Sources)
    feeds: [
        { id: 'f1', name: 'TechCrunch', url: 'https://techcrunch.com/feed/', type: 'rss', category: '科技', isEnabled: true, isPreset: true, credibilityWeight: 4.0, lastFetchedAt: null, fetchErrorCount: 0, icon: 'T', description: 'The latest tech news, startups, and profound engineering discussions.' },
        { id: 'f2', name: '少数派', url: 'https://sspai.com/feed', type: 'rss', category: '科技', isEnabled: true, isPreset: true, credibilityWeight: 4.5, lastFetchedAt: null, fetchErrorCount: 0, icon: '少', description: 'High-quality digital life, productivity tools, and modern lifestyle concepts.' },
        { id: 'f3', name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml', type: 'rss', category: '科技', isEnabled: false, isPreset: true, credibilityWeight: 4.0, lastFetchedAt: null, fetchErrorCount: 0, icon: 'V', description: '前沿数码与科技生活' },
        { id: 'f4', name: 'MIT Tech Review', url: 'https://www.technologyreview.com/feed/', type: 'rss', category: '科技', isEnabled: false, isPreset: true, credibilityWeight: 5.0, lastFetchedAt: null, fetchErrorCount: 0, icon: 'M', description: '商业技术权威评论' },
        { id: 'f5', name: 'Bloomberg', url: 'https://feeds.bloomberg.com/news.rss', type: 'rss', category: '商业', isEnabled: false, isPreset: true, credibilityWeight: 4.5, lastFetchedAt: null, fetchErrorCount: 0, icon: 'B', description: '实时市场与财经决策' },
        { id: 'f6', name: '晚点 LatePost', url: 'https://www.latepost.com/rss', type: 'rss', category: '商业', isEnabled: true, isPreset: true, credibilityWeight: 4.5, lastFetchedAt: null, fetchErrorCount: 0, icon: '晚', description: '深度商业报道' },
        { id: 'f7', name: 'The Economist', url: 'https://www.economist.com/rss', type: 'rss', category: '商业', isEnabled: false, isPreset: true, credibilityWeight: 5.0, lastFetchedAt: null, fetchErrorCount: 0, icon: 'E', description: '全球洞察与周刊精选' },
    ],

    // Articles
    articles: [
        {
            id: 'a1',
            title: 'OpenAI 发布全新推理模型 GPT-Next，实现突破性进展',
            url: 'https://techcrunch.com/2026/06/06/openai-gpt-next',
            content: '新模型在复杂逻辑推理和长期记忆规划方面展现了惊人的能力。在传统的测试中，模型往往会因为逻辑跳跃而产生错误，但 GPT-Next 会在内部生成数千个验证步骤，并通过强化学习自主发现并纠正其中的错误...',
            summaryOneLine: '新模型在复杂逻辑推理和长期记忆规划方面展现惊人能力',
            summaryPoints: ['采用全新的系统二思维架构，支持更长路径的逻辑推理', '在 AIME 基准测试中将分数提升 40%，展现出远超 GPT-4 的多维认知', '模型大幅降低了幻觉率，并引入了交互式纠错功能'],
            sourceName: 'TechCrunch',
            sourceUrl: 'https://techcrunch.com/feed/',
            category: '科技',
            publishedAt: new Date('2026-06-06T14:30:00').getTime(),
            fetchedAt: new Date('2026-06-06T15:00:00').getTime(),
            scoreTotal: 9.8,
            scoreCredibility: 5.0,
            scoreDensity: 4.8,
            scoreMode: 'llm',
            isRead: false,
            isFavorited: false,
            contentStatus: 'full',
            mergedArticleIds: [],
            briefingId: 'b1',
        },
        {
            id: 'a2',
            title: '苹果 iOS 20 将深度集成端侧大模型，系统级重构将大幅降低对云端算力的依赖',
            url: 'https://www.theverge.com/2026/06/06/ios20-on-device-llm',
            content: '据彭博社报道，即将发布的 iOS 20 将首次实现系统级端侧大模型集成，这意味着 Siri 和 Spotlight 等核心功能将完全在本地运行，无需联网即可完成复杂的自然语言理解和生成任务...',
            summaryOneLine: 'iOS 20 将首次实现系统级端侧大模型集成，核心功能本地运行',
            summaryPoints: ['Siri 和 Spotlight 将完全在本地运行，无需联网', '采用 Apple Silicon 神经引擎加速，推理速度提升 3 倍', '隐私保护大幅增强，用户数据不再上传云端'],
            sourceName: 'The Verge',
            sourceUrl: 'https://www.theverge.com/rss/index.xml',
            category: '科技',
            publishedAt: new Date('2026-06-06T12:00:00').getTime(),
            fetchedAt: new Date('2026-06-06T15:00:00').getTime(),
            scoreTotal: 8.2,
            scoreCredibility: 4.0,
            scoreDensity: 4.2,
            scoreMode: 'llm',
            isRead: false,
            isFavorited: false,
            contentStatus: 'full',
            mergedArticleIds: [],
            briefingId: 'b1',
        },
        {
            id: 'a3',
            title: '全球新能源汽车供应链面临重组，本土企业迎来机遇',
            url: 'https://www.latepost.com/news/20260606-nev-supply-chain',
            content: '受地缘政治及原材料价格波动影响，多家跨国车企宣布调整供应链策略，将更多零部件采购转向中国本土供应商。这一转变意味着中国新能源汽车产业链将迎来新一轮发展机遇...',
            summaryOneLine: '跨国车企调整供应链策略，中国本土供应商迎来发展机遇',
            summaryPoints: ['多家跨国车企宣布增加中国本土零部件采购比例', '电池、电机、电控等核心零部件国产化率持续提升', '预计2027年中国新能源汽车出口量将增长30%'],
            sourceName: '晚点 LatePost',
            sourceUrl: 'https://www.latepost.com/rss',
            category: '商业',
            publishedAt: new Date('2026-06-06T10:00:00').getTime(),
            fetchedAt: new Date('2026-06-06T15:00:00').getTime(),
            scoreTotal: 8.5,
            scoreCredibility: 4.5,
            scoreDensity: 4.0,
            scoreMode: 'llm',
            isRead: false,
            isFavorited: false,
            contentStatus: 'full',
            mergedArticleIds: [],
            briefingId: 'b1',
        },
        {
            id: 'a4',
            title: '苹果 WWDC 2026 前瞻：iOS 20 将带来深度集成的端侧 AI',
            url: 'https://www.theverge.com/2026/06/05/wwdc-2026-preview',
            content: '据彭博社报道，即将发布的 iOS 20 将首次实现系统级端侧大模型集成，这意味着 Siri 和 Spotlight 等核心功能将完全在本地运行...',
            summaryOneLine: 'WWDC 2026 将展示 iOS 20 的端侧 AI 集成能力',
            summaryPoints: ['系统级端侧大模型集成', 'Siri 和 Spotlight 本地运行', 'Apple Silicon 神经引擎加速'],
            sourceName: 'The Verge',
            sourceUrl: 'https://www.theverge.com/rss/index.xml',
            category: '科技',
            publishedAt: new Date('2026-06-05T18:00:00').getTime(),
            fetchedAt: new Date('2026-06-06T15:00:00').getTime(),
            scoreTotal: 7.2,
            scoreCredibility: 4.0,
            scoreDensity: 3.2,
            scoreMode: 'local',
            isRead: true,
            isFavorited: true,
            contentStatus: 'full',
            mergedArticleIds: [],
            briefingId: 'b1',
        },
        {
            id: 'a5',
            title: '生成式 AI 对现代传媒的重塑：深度研究与行业展望',
            url: 'https://www.technologyreview.com/2026/06/06/ai-media-research',
            content: '在这个信息过载的时代，如何从海量数据中甄别出有价值的内容？"拾光"不仅是一个聚合器，更是您的私人智囊团。通过多维度的 AI 评估算法，我们确保每一篇推送到您眼前的资讯都经过严格的质量校验...',
            summaryOneLine: 'AI 评估算法帮助用户从海量数据中甄别有价值的内容',
            summaryPoints: ['多维度的 AI 评估算法确保资讯质量', '个性化推荐系统提升信息获取效率', '生成式 AI 正在重塑传媒行业的生产流程'],
            sourceName: 'Technological Review',
            sourceUrl: 'https://www.technologyreview.com/feed/',
            category: '科技',
            publishedAt: new Date('2026-06-06T08:00:00').getTime(),
            fetchedAt: new Date('2026-06-06T15:00:00').getTime(),
            scoreTotal: 9.8,
            scoreCredibility: 5.0,
            scoreDensity: 4.8,
            scoreMode: 'llm',
            isRead: false,
            isFavorited: false,
            contentStatus: 'full',
            mergedArticleIds: [],
            briefingId: null,
        },
    ],

    // Briefings
    briefings: [
        {
            id: 'b1',
            date: '2026-06-06',
            articleCount: 20,
            configSnapshot: { categories: ['科技', '商业'], dailyCount: 20, domesticRatio: 0.6 },
            generatedAt: new Date('2026-06-06T08:00:00').getTime(),
            triggerType: 'scheduled',
            status: 'completed',
            aiInsight: '今日人工智能领域有重大技术突破，OpenAI 发布新模型，大幅提升了逻辑推理与跨模态理解能力。同时，全球供应链调整导致新能源板块震荡...',
        },
    ],

    // Execution Logs
    executionLogs: [
        { id: 'l1', taskType: 'briefing', status: 'success', startedAt: new Date('2026-06-06T08:00:00').getTime(), completedAt: new Date('2026-06-06T08:00:48').getTime(), duration: 48000, errorMessage: null, details: '耗时: 840ms | 精选: 12条', label: '晨间简报生成完成' },
        { id: 'l2', taskType: 'fetch', status: 'failed', startedAt: new Date('2026-06-06T07:58:00').getTime(), completedAt: new Date('2026-06-06T07:58:05').getTime(), duration: 5000, errorMessage: 'RSS 源抓取超时: TechCrunch', details: '耗时: 5000ms | 重试: 3/3', label: 'RSS 源抓取超时: TechCrunch' },
        { id: 'l3', taskType: 'score', status: 'success', startedAt: new Date('2026-06-06T07:55:00').getTime(), completedAt: new Date('2026-06-06T07:55:02').getTime(), duration: 2100, errorMessage: null, details: '耗时: 2.1s | 处理: 156篇', label: 'AI 内容质量评分任务' },
        { id: 'l4', taskType: 'fetch', status: 'success', startedAt: new Date('2026-06-06T07:50:00').getTime(), completedAt: new Date('2026-06-06T07:50:01').getTime(), duration: 1200, errorMessage: null, details: '耗时: 1.2s | 新增: 42条', label: 'Twitter 关键词订阅更新' },
    ],

    // Data methods
    getArticles(filter = 'all') {
        let articles = [...this.articles];
        switch (filter) {
            case 'unread':
                articles = articles.filter(a => !a.isRead);
                break;
            case 'favorited':
                articles = articles.filter(a => a.isFavorited);
                break;
        }
        return articles.sort((a, b) => b.scoreTotal - a.scoreTotal);
    },

    getArticleById(id) {
        return this.articles.find(a => a.id === id);
    },

    getFavoritedArticles() {
        return this.articles.filter(a => a.isFavorited).sort((a, b) => b.scoreTotal - a.scoreTotal);
    },

    getBriefingByDate(date) {
        return this.briefings.find(b => b.date === date);
    },

    getTodayBriefing() {
        const today = new Date().toISOString().split('T')[0];
        return this.getBriefingByDate(today) || this.briefings[0];
    },

    getBriefingArticles(briefingId) {
        return this.articles.filter(a => a.briefingId === briefingId).sort((a, b) => b.scoreTotal - a.scoreTotal);
    },

    getFeeds() {
        return this.feeds;
    },

    getEnabledFeeds() {
        return this.feeds.filter(f => f.isEnabled);
    },

    getFeedsByCategory(category) {
        return this.feeds.filter(f => f.category === category);
    },

    getExecutionLogs(filter = 'all') {
        let logs = [...this.executionLogs];
        if (filter !== 'all') {
            logs = logs.filter(l => l.taskType === filter || (filter === 'error' && l.status === 'failed'));
        }
        return logs.sort((a, b) => b.startedAt - a.startedAt);
    },

    toggleFavorite(articleId) {
        const article = this.articles.find(a => a.id === articleId);
        if (article) {
            article.isFavorited = !article.isFavorited;
            return article.isFavorited;
        }
        return null;
    },

    markAsRead(articleId) {
        const article = this.articles.find(a => a.id === articleId);
        if (article) {
            article.isRead = true;
        }
    },

    updateUserConfig(config) {
        this.userConfig = { ...this.userConfig, ...config };
    },

    updateLLMConfig(config) {
        this.llmConfig = { ...this.llmConfig, ...config };
    },

    toggleFeed(feedId) {
        const feed = this.feeds.find(f => f.id === feedId);
        if (feed) {
            feed.isEnabled = !feed.isEnabled;
            return feed.isEnabled;
        }
        return null;
    },

    // Export functions
    exportArticle(articleId, format) {
        const article = this.getArticleById(articleId);
        if (!article) return null;
        if (format === 'json') {
            return JSON.stringify(article, null, 2);
        }
        if (format === 'markdown') {
            return `# ${article.title}\n\n> 来源: ${article.sourceName} | 评分: ${article.scoreTotal}\n\n${article.content}\n\n[阅读原文](${article.url})`;
        }
        return null;
    },

    exportBriefing(briefingId, format) {
        const briefing = this.briefings.find(b => b.id === briefingId);
        if (!briefing) return null;
        const articles = this.getBriefingArticles(briefingId);
        if (format === 'markdown') {
            let md = `# 拾光日报 · ${briefing.date}\n\n> 今日精选 ${articles.length} 条 | AI 精选 ${briefing.articleCount} 条\n\n`;
            if (briefing.aiInsight) {
                md += `## AI Insight\n\n${briefing.aiInsight}\n\n---\n\n`;
            }
            articles.forEach(a => {
                md += `### ${a.title}\n\n> 评分: ${a.scoreTotal} | 来源: ${a.sourceName}\n\n${a.summaryOneLine}\n\n- ${a.summaryPoints.join('\n- ')}\n\n[阅读原文](${a.url})\n\n---\n\n`;
            });
            return md;
        }
        if (format === 'json') {
            return JSON.stringify({ briefing, articles }, null, 2);
        }
        return null;
    },

    exportAll(format) {
        if (format === 'json') {
            return JSON.stringify({
                exportMeta: {
                    app: '拾光 / Glean',
                    version: '1.0',
                    exportedAt: new Date().toISOString(),
                    articleCount: this.articles.length,
                    briefingCount: this.briefings.length,
                    feedCount: this.feeds.length,
                },
                userConfig: this.userConfig,
                llmConfig: this.llmConfig,
                feeds: this.feeds,
                articles: this.articles,
                briefings: this.briefings,
                executionLogs: this.executionLogs,
            }, null, 2);
        }
        if (format === 'markdown') {
            let md = `# 拾光 / Glean 数据导出\n\n`;
            md += `> 导出时间: ${new Date().toLocaleString('zh-CN')}\n\n`;
            md += `---\n\n`;
            md += `## 统计概览\n\n`;
            md += `- 文章总数: ${this.articles.length}\n`;
            md += `- 简报总数: ${this.briefings.length}\n`;
            md += `- 数据源: ${this.feeds.length}\n`;
            md += `- 收藏文章: ${this.articles.filter(a => a.isFavorited).length}\n\n`;
            md += `---\n\n`;
            md += `## 文章列表\n\n`;
            this.articles.forEach((a, i) => {
                md += `### ${i + 1}. ${a.title}\n\n`;
                md += `> 来源: ${a.sourceName} | 评分: ${a.scoreTotal} | ${a.isRead ? '已读' : '未读'} | ${a.isFavorited ? '已收藏' : ''}\n\n`;
                md += `${a.summaryOneLine}\n\n`;
                md += `- ${a.summaryPoints.join('\n- ')}\n\n`;
                md += `[阅读原文](${a.url})\n\n`;
                md += `---\n\n`;
            });
            return md;
        }
        return null;
    },

    // Storage statistics
    getStorageStats() {
        const articlesSize = JSON.stringify(this.articles).length;
        const briefingsSize = JSON.stringify(this.briefings).length;
        const feedsSize = JSON.stringify(this.feeds).length;
        const logsSize = JSON.stringify(this.executionLogs).length;
        const totalSize = articlesSize + briefingsSize + feedsSize + logsSize;
        const maxSize = 512 * 1024 * 1024; // 512MB

        return {
            totalSize,
            maxSize,
            usedPercent: Math.round((totalSize / maxSize) * 100),
            breakdown: {
                articles: articlesSize,
                briefings: briefingsSize,
                feeds: feedsSize,
                logs: logsSize,
            },
            counts: {
                articles: this.articles.length,
                briefings: this.briefings.length,
                feeds: this.feeds.length,
                logs: this.executionLogs.length,
                favorited: this.articles.filter(a => a.isFavorited).length,
                unread: this.articles.filter(a => !a.isRead).length,
            }
        };
    },

    // Clear data by type
    clearData(type) {
        switch (type) {
            case 'articles':
                this.articles = [];
                break;
            case 'logs':
                this.executionLogs = [];
                break;
            case 'briefings':
                this.briefings = [];
                break;
            case 'all':
                this.articles = [];
                this.briefings = [];
                this.executionLogs = [];
                break;
        }
    },
};
