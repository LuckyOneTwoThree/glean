// Glean App - Page Render Functions
// All page rendering functions follow the DESIGN.md design system

// ==================== Shared Components ====================

function renderArticleCard(article, options = {}) {
    const { showUnreadDot = true, animate = true, layout = 'home' } = options;
    const scoreClass = article.scoreTotal >= 8 ? 'score-badge-high' : article.scoreTotal >= 6 ? 'score-badge-mid' : 'score-badge-low';
    const readClass = article.isRead ? 'text-on-surface-variant' : 'text-on-surface';
    const readOpacity = article.isRead ? 'opacity-80' : '';
    const favoriteIcon = article.isFavorited ? 'favorite' : 'favorite_border';
    const favoriteFilled = article.isFavorited ? 'filled' : '';
    const favoriteColor = article.isFavorited ? 'text-error' : 'text-on-surface-variant';
    const timeStr = getRelativeTime(article.publishedAt);
    const unreadDot = !article.isRead && showUnreadDot ? `<span class="unread-dot absolute top-3 right-12 w-2 h-2 rounded-full bg-unread-blue"></span>` : '';
    const animationClass = animate ? 'animate-fade-in-up' : '';

    // Home layout: card style with score on right (per design _4)
    if (layout === 'home') {
        return `
            <div class="article-card content-visibility-auto group relative mx-4 mt-3 p-4 rounded-xl bg-surface-container-lowest border border-outline-variant/20 cursor-pointer hover:shadow-card transition-all duration-200 ${readOpacity} ${animationClass}" data-id="${article.id}" style="${animate ? 'animation-delay: 0ms;' : ''}">
                ${unreadDot}
                <div class="flex items-start gap-3">
                    <!-- Content -->
                    <div class="flex-1 min-w-0">
                        <h3 class="font-serif-display text-body-md font-semibold ${readClass} leading-snug line-clamp-2 mb-1.5">${article.title}</h3>
                        <p class="text-body-sm text-on-surface-variant line-clamp-1 mb-2">${article.summaryOneLine}</p>
                        <div class="flex items-center gap-2">
                            <span class="px-2 py-0.5 rounded-full bg-surface-container-high text-label-sm text-on-surface-variant font-mono-code">${article.sourceName}</span>
                            <span class="text-label-sm text-on-surface-variant">${timeStr}</span>
                        </div>
                    </div>
                    <!-- Score & Actions -->
                    <div class="flex-shrink-0 flex flex-col items-end gap-2">
                        <div class="px-2 py-1 rounded-lg bg-surface-container-high ${scoreClass}">
                            <span class="text-label-sm font-bold">${article.scoreTotal.toFixed(1)}</span>
                        </div>
                        <button class="favorite-btn p-1 rounded-full hover:bg-surface-container transition-colors" data-id="${article.id}">
                            <span class="material-symbols-outlined ${favoriteFilled} ${favoriteColor} text-base">${favoriteIcon}</span>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    // Briefing layout: compact with small score (per design _3)
    return `
        <div class="briefing-article-card group relative flex items-start gap-3 py-3 cursor-pointer ${animationClass}" data-id="${article.id}">
            <div class="flex-1 min-w-0">
                <div class="flex items-start gap-2">
                    <span class="text-headline-sm font-bold ${scoreClass} flex-shrink-0" style="min-width: 2rem;">${article.scoreTotal.toFixed(1)}</span>
                    <h4 class="font-serif-display text-body-md font-semibold text-on-surface leading-snug">${article.title}</h4>
                </div>
                <p class="text-body-sm text-on-surface-variant mt-1 line-clamp-1 ml-10">${article.summaryOneLine}</p>
                <span class="text-label-sm text-on-surface-variant font-mono-code ml-10">${article.sourceName}</span>
            </div>
        </div>
    `;
}

function getRelativeTime(timestamp) {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return '刚刚';
    if (minutes < 60) return `${minutes}分钟前`;
    if (hours < 24) return `${hours}小时前`;
    if (days < 7) return `${days}天前`;
    return new Date(timestamp).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
}

function renderScoreBadge(score) {
    const scoreClass = score >= 8 ? 'score-badge-high' : score >= 6 ? 'score-badge-mid' : 'score-badge-low';
    return `
        <div class="w-14 h-14 rounded-full border-2 ${scoreClass} flex items-center justify-center">
            <span class="text-headline-sm font-semibold">${score.toFixed(1)}</span>
        </div>
    `;
}

function renderSectionHeader(title) {
    return `
        <div class="flex items-center gap-3 py-3 px-4">
            <div class="h-px flex-1 bg-outline-variant"></div>
            <span class="text-label-sm text-on-surface-variant font-medium whitespace-nowrap">${title}</span>
            <div class="h-px flex-1 bg-outline-variant"></div>
        </div>
    `;
}

function renderBackButton() {
    return `
        <button class="back-btn flex items-center gap-1 text-body-md text-on-surface-variant hover:text-on-surface transition-colors">
            <span class="material-symbols-outlined">arrow_back</span>
            <span>返回</span>
        </button>
    `;
}

function renderPageHeader(title, subtitle = '') {
    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center justify-between px-4 py-3">
                <div>
                    <h1 class="text-headline-sm font-sans-body font-semibold text-on-surface">${title}</h1>
                    ${subtitle ? `<p class="text-body-sm text-on-surface-variant mt-0.5">${subtitle}</p>` : ''}
                </div>
            </div>
        </div>
    `;
}

function renderLogItem(log) {
    const statusColor = log.status === 'success' ? 'text-green-600' : 'text-error';
    const statusIcon = log.status === 'success' ? 'check_circle' : 'error';
    const timeStr = new Date(log.startedAt).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });

    return `
        <div class="flex items-start gap-3 p-4 border-b border-outline-variant/30">
            <span class="material-symbols-outlined ${statusColor} text-lg flex-shrink-0 mt-0.5">${statusIcon}</span>
            <div class="flex-1 min-w-0">
                <div class="text-body-sm font-medium text-on-surface">${log.label}</div>
                <div class="text-label-sm text-on-surface-variant mt-1">${log.details}</div>
                <div class="text-label-sm text-on-surface-variant mt-0.5">${timeStr}</div>
            </div>
        </div>
    `;
}

// ==================== Welcome Page ====================

function renderWelcomePage() {
    return `
        <div class="min-h-screen flex flex-col items-center justify-center px-6 safe-top safe-bottom">
            <div class="text-center mb-12">
                <h1 class="font-serif-display text-headline-xl text-ink-blue mb-4">拾光</h1>
                <p class="text-body-lg text-on-surface-variant max-w-xs mx-auto leading-relaxed">
                    在信息洪流中，为您甄选最有价值的资讯
                </p>
            </div>
            <div class="w-full max-w-xs space-y-4">
                <button class="start-btn w-full py-4 bg-primary text-on-primary rounded-full text-label-md font-semibold hover:bg-ink-blue transition-colors shadow-ambient">
                    开始体验
                </button>
                <p class="text-center text-label-sm text-on-surface-variant">
                    只需几步，即可定制您的专属资讯简报
                </p>
            </div>
        </div>
    `;
}

// ==================== Onboarding Page ====================

function renderOnboardingPage() {
    return `
        <div class="min-h-screen flex flex-col safe-top safe-bottom">
            <!-- Step 1: Categories -->
            <div class="onboarding-step flex-1 px-6 py-8">
                <div class="mb-8">
                    <div class="text-label-sm text-on-surface-variant mb-2">Step 1 of 5</div>
                    <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">选择关注方向</h2>
                    <p class="text-body-md text-on-surface-variant">选择您感兴趣的领域，我们将为您筛选相关资讯</p>
                </div>
                <div class="space-y-3">
                    ${['科技', '商业', '政治', '社会', '娱乐', '体育'].map(cat => `
                        <label class="flex items-center gap-3 p-4 rounded-xl bg-surface-container-low border border-outline-variant/30 cursor-pointer hover:bg-surface-container transition-colors">
                            <input type="checkbox" class="category-checkbox w-5 h-5 rounded border-outline text-primary focus:ring-primary" value="${cat}" ${GleanData.userConfig.categories.includes(cat) ? 'checked' : ''}>
                            <span class="text-body-md text-on-surface">${cat}</span>
                        </label>
                    `).join('')}
                </div>
            </div>

            <!-- Step 2: Data Sources -->
            <div class="onboarding-step hidden flex-1 px-6 py-8">
                <div class="mb-8">
                    <div class="text-label-sm text-on-surface-variant mb-2">Step 2 of 5</div>
                    <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">选择数据源</h2>
                    <p class="text-body-md text-on-surface-variant">选择您信任的信息来源</p>
                </div>
                <div class="space-y-3">
                    ${GleanData.feeds.filter(f => f.isPreset).map(feed => `
                        <label class="flex items-center gap-3 p-4 rounded-xl bg-surface-container-low border border-outline-variant/30 cursor-pointer hover:bg-surface-container transition-colors">
                            <input type="checkbox" class="feed-checkbox w-5 h-5 rounded border-outline text-primary focus:ring-primary" value="${feed.id}" ${feed.isEnabled ? 'checked' : ''}>
                            <div class="flex-1">
                                <div class="text-body-md font-medium text-on-surface">${feed.name}</div>
                                <div class="text-body-sm text-on-surface-variant">${feed.description}</div>
                            </div>
                        </label>
                    `).join('')}
                </div>
            </div>

            <!-- Step 3: Briefing Preferences -->
            <div class="onboarding-step hidden flex-1 px-6 py-8">
                <div class="mb-8">
                    <div class="text-label-sm text-on-surface-variant mb-2">Step 3 of 5</div>
                    <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">配置简报偏好</h2>
                    <p class="text-body-md text-on-surface-variant">定制您的每日简报</p>
                </div>
                <div class="space-y-6">
                    <!-- Daily Count -->
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-3 block">每日精选数量</label>
                        <div class="grid grid-cols-4 gap-3">
                            ${[10, 20, 30, 50].map(count => `
                                <button class="count-selector py-3 rounded-xl text-body-md font-medium transition-colors ${count === 20 ? 'bg-primary text-on-primary' : 'bg-surface-container-high text-on-surface'}" data-count="${count}">
                                    ${count}
                                </button>
                            `).join('')}
                        </div>
                    </div>
                    <!-- Domestic Ratio -->
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-3 block">国内外比例</label>
                        <div class="flex items-center gap-3">
                            <span class="text-body-sm text-on-surface-variant">国内</span>
                            <input type="range" id="domestic-ratio" min="0" max="100" value="60" class="flex-1">
                            <span class="text-body-sm text-on-surface-variant">国外</span>
                        </div>
                        <div class="text-center text-label-sm text-on-surface-variant mt-2" id="domestic-ratio-value">60%</div>
                    </div>
                    <!-- Push Time -->
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-3 block">推送时间</label>
                        <input type="time" id="push-time" value="08:00" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    </div>
                </div>
            </div>

            <!-- Step 4: AI Mode -->
            <div class="onboarding-step hidden flex-1 px-6 py-8">
                <div class="mb-8">
                    <div class="text-label-sm text-on-surface-variant mb-2">Step 4 of 5</div>
                    <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">选择 AI 引擎</h2>
                    <p class="text-body-md text-on-surface-variant">选择适合您的 AI 分析模式</p>
                </div>
                <div class="space-y-3">
                    <label class="flex items-start gap-3 p-4 rounded-xl bg-surface-container-low border-2 border-primary cursor-pointer">
                        <input type="radio" name="ai-mode" value="hybrid" class="mt-1 w-5 h-5 text-primary" checked>
                        <div>
                            <div class="text-body-md font-semibold text-on-surface">混合模式（推荐）</div>
                            <div class="text-body-sm text-on-surface-variant mt-1">本地规则评分 + LLM 生成摘要，平衡质量与成本</div>
                        </div>
                    </label>
                    <label class="flex items-start gap-3 p-4 rounded-xl bg-surface-container-low border border-outline-variant/30 cursor-pointer">
                        <input type="radio" name="ai-mode" value="economy" class="mt-1 w-5 h-5 text-primary">
                        <div>
                            <div class="text-body-md font-semibold text-on-surface">省钱模式</div>
                            <div class="text-body-sm text-on-surface-variant mt-1">纯本地规则引擎，零 API 成本</div>
                        </div>
                    </label>
                    <label class="flex items-start gap-3 p-4 rounded-xl bg-surface-container-low border border-outline-variant/30 cursor-pointer">
                        <input type="radio" name="ai-mode" value="quality" class="mt-1 w-5 h-5 text-primary">
                        <div>
                            <div class="text-body-md font-semibold text-on-surface">质量模式</div>
                            <div class="text-body-sm text-on-surface-variant mt-1">LLM 评分 + 生成式摘要，最高质量</div>
                        </div>
                    </label>
                </div>
            </div>

            <!-- Step 5: LLM Config -->
            <div class="onboarding-step hidden flex-1 px-6 py-8">
                <div class="mb-8">
                    <div class="text-label-sm text-on-surface-variant mb-2">Step 5 of 5</div>
                    <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">配置 LLM</h2>
                    <p class="text-body-md text-on-surface-variant">配置您的 AI 服务提供商（省钱模式可跳过）</p>
                </div>
                <div class="space-y-4">
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-2 block">提供商</label>
                        <select id="llm-provider" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                            <option value="mimo">mimo</option>
                            <option value="openai">OpenAI</option>
                            <option value="deepseek">DeepSeek</option>
                            <option value="custom">自定义</option>
                        </select>
                    </div>
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-2 block">API Key</label>
                        <input type="password" id="llm-api-key" placeholder="输入您的 API Key" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    </div>
                    <div>
                        <label class="text-label-md font-semibold text-on-surface mb-2 block">模型</label>
                        <select id="llm-model" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                            <option value="gpt-4o">gpt-4o</option>
                            <option value="gpt-4o-mini">gpt-4o-mini</option>
                        </select>
                    </div>
                    <button class="test-connection-btn w-full py-3 border border-primary text-primary rounded-full text-label-md font-semibold hover:bg-primary-container transition-colors">
                        测试连接
                    </button>
                </div>
            </div>

            <!-- Navigation Buttons -->
            <div class="px-6 py-4 border-t border-outline-variant/30">
                <div class="flex gap-3">
                    <button class="onboarding-prev-btn hidden flex-1 py-3 border border-outline text-on-surface rounded-full text-label-md font-semibold hover:bg-surface-container transition-colors">
                        上一步
                    </button>
                    <button class="onboarding-next-btn flex-1 py-3 bg-primary text-on-primary rounded-full text-label-md font-semibold hover:bg-ink-blue transition-colors shadow-ambient">
                        下一步
                    </button>
                </div>
            </div>
        </div>
    `;
}

// ==================== Home Page ====================

function renderHomePage() {
    const articles = GleanData.getArticles('all');
    const unreadCount = articles.filter(a => !a.isRead).length;

    return `
        ${renderPageHeader('资讯列表', `${articles.length} 篇文章 · ${unreadCount} 篇未读`)}

        <!-- Filter Tabs -->
        <div class="sticky top-[57px] z-30 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 px-4 py-3">
            <div class="flex items-center gap-2">
                <button class="filter-tab px-4 py-2 rounded-full text-label-sm font-medium bg-primary text-on-primary transition-colors" data-filter="all">
                    全部
                </button>
                <button class="filter-tab px-4 py-2 rounded-full text-label-sm font-medium bg-surface-container-high text-on-surface-variant transition-colors" data-filter="unread">
                    未读
                </button>
                <button class="filter-tab px-4 py-2 rounded-full text-label-sm font-medium bg-surface-container-high text-on-surface-variant transition-colors" data-filter="favorited">
                    收藏
                </button>
                <div class="flex-1"></div>
                <button class="sort-toggle flex items-center gap-1 text-label-sm text-on-surface-variant hover:text-on-surface transition-colors">
                    <span class="material-symbols-outlined text-lg">sort</span>
                    <span>价值分</span>
                </button>
            </div>
        </div>

        <!-- Article List -->
        <div id="article-list" class="divide-y divide-outline-variant/30">
            ${articles.length > 0 ? articles.map(article => renderArticleCard(article)).join('') : `
                <div class="flex flex-col items-center justify-center py-16 px-6">
                    <span class="material-symbols-outlined text-6xl text-outline-variant mb-4">inbox</span>
                    <p class="text-body-md text-on-surface-variant text-center">暂无资讯</p>
                    <p class="text-body-sm text-on-surface-variant text-center mt-1">请检查数据源配置或手动刷新</p>
                </div>
            `}
        </div>
    `;
}

// ==================== Briefing Page ====================

function renderBriefingPage() {
    const briefing = GleanData.getTodayBriefing();
    const articles = GleanData.getBriefingArticles(briefing.id);
    const dateStr = new Date(briefing.generatedAt).toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' });

    return `
        ${renderPageHeader('今日简报', dateStr)}

        <!-- AI Insight -->
        ${briefing.aiInsight ? `
            <div class="mx-4 mt-4 p-4 rounded-xl bg-primary-container/30 border border-primary-container">
                <div class="flex items-center gap-2 mb-2">
                    <span class="material-symbols-outlined text-golden-hour">auto_awesome</span>
                    <span class="text-label-md font-semibold text-on-surface">AI Insight</span>
                </div>
                <p class="text-body-sm text-on-surface-variant leading-relaxed">${briefing.aiInsight}</p>
            </div>
        ` : ''}

        <!-- Stats -->
        <div class="flex items-center justify-between px-4 py-3">
            <div class="text-label-sm text-on-surface-variant">
                今日精选 <span class="text-on-surface font-semibold">${articles.length}</span> 条
            </div>
            <div class="flex items-center gap-2">
                <button class="regenerate-btn flex items-center gap-1 px-3 py-1.5 rounded-full border border-outline text-label-sm text-on-surface-variant hover:bg-surface-container transition-colors">
                    <span class="material-symbols-outlined text-base">refresh</span>
                    <span>重新生成</span>
                </button>
                <button class="export-briefing-btn flex items-center gap-1 px-3 py-1.5 rounded-full border border-outline text-label-sm text-on-surface-variant hover:bg-surface-container transition-colors">
                    <span class="material-symbols-outlined text-base">download</span>
                    <span>导出</span>
                </button>
            </div>
        </div>

        <!-- Articles by Category -->
        <div class="px-4 pb-4">
            ${renderSectionHeader('🤖 AI')}
            ${articles.filter(a => a.category === '科技').map(article => `
                <div class="briefing-article-card flex items-start gap-3 p-3 rounded-xl bg-surface-container-low border border-outline-variant/20 cursor-pointer hover:bg-surface-container transition-colors mb-2" data-id="${article.id}">
                    <div class="flex-shrink-0 w-8 h-8 rounded-full border-2 ${article.scoreTotal >= 8 ? 'score-badge-high' : 'score-badge-mid'} flex items-center justify-center">
                        <span class="text-label-sm font-semibold">${article.scoreTotal.toFixed(1)}</span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h4 class="font-serif-display text-body-sm font-medium text-on-surface line-clamp-2 leading-snug">${article.title}</h4>
                        <p class="text-label-sm text-on-surface-variant mt-1 line-clamp-1">${article.summaryOneLine}</p>
                    </div>
                </div>
            `).join('')}

            ${renderSectionHeader('💼 商业')}
            ${articles.filter(a => a.category === '商业').map(article => `
                <div class="briefing-article-card flex items-start gap-3 p-3 rounded-xl bg-surface-container-low border border-outline-variant/20 cursor-pointer hover:bg-surface-container transition-colors mb-2" data-id="${article.id}">
                    <div class="flex-shrink-0 w-8 h-8 rounded-full border-2 ${article.scoreTotal >= 8 ? 'score-badge-high' : 'score-badge-mid'} flex items-center justify-center">
                        <span class="text-label-sm font-semibold">${article.scoreTotal.toFixed(1)}</span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h4 class="font-serif-display text-body-sm font-medium text-on-surface line-clamp-2 leading-snug">${article.title}</h4>
                        <p class="text-label-sm text-on-surface-variant mt-1 line-clamp-1">${article.summaryOneLine}</p>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

// ==================== Favorites Page ====================

function renderFavoritesPage() {
    const articles = GleanData.getFavoritedArticles();

    return `
        ${renderPageHeader('收藏', `${articles.length} 篇收藏`)}

        <div id="article-list" class="divide-y divide-outline-variant/30">
            ${articles.length > 0 ? articles.map(article => renderArticleCard(article)).join('') : `
                <div class="flex flex-col items-center justify-center py-16 px-6">
                    <span class="material-symbols-outlined text-6xl text-outline-variant mb-4">bookmark_border</span>
                    <p class="text-body-md text-on-surface-variant text-center">暂无收藏</p>
                    <p class="text-body-sm text-on-surface-variant text-center mt-1">点击文章右侧的心形图标收藏</p>
                </div>
            `}
        </div>
    `;
}

// ==================== Settings Page ====================

function renderSettingsPage() {
    return `
        ${renderPageHeader('设置')}

        <div class="px-4 py-2 space-y-2">
            <!-- Briefing Config -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="briefing-config">
                <span class="material-symbols-outlined text-on-surface-variant">newspaper</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">简报配置</div>
                    <div class="text-body-sm text-on-surface-variant">关注方向、数量、推送时间</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>

            <!-- Data Sources -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="feed-select">
                <span class="material-symbols-outlined text-on-surface-variant">rss_feed</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">数据源管理</div>
                    <div class="text-body-sm text-on-surface-variant">RSS 订阅、API 源</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>

            <!-- AI Settings -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="llm-config">
                <span class="material-symbols-outlined text-on-surface-variant">psychology</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">AI 设置</div>
                    <div class="text-body-sm text-on-surface-variant">模型选择、API 配置</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>

            <!-- Fetch Settings -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="fetch-settings">
                <span class="material-symbols-outlined text-on-surface-variant">sync</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">采集设置</div>
                    <div class="text-body-sm text-on-surface-variant">频率、网络策略</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>

            <!-- Data Management -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="data-management">
                <span class="material-symbols-outlined text-on-surface-variant">storage</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">数据管理</div>
                    <div class="text-body-sm text-on-surface-variant">导出、清理、备份</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>

            <!-- Execution Logs -->
            <div class="settings-row flex items-center gap-4 p-4 rounded-xl bg-surface-container-low cursor-pointer hover:bg-surface-container transition-colors" data-page="execution-logs">
                <span class="material-symbols-outlined text-on-surface-variant">history</span>
                <div class="flex-1">
                    <div class="text-body-md font-medium text-on-surface">执行记录</div>
                    <div class="text-body-sm text-on-surface-variant">采集、评分、生成日志</div>
                </div>
                <span class="material-symbols-outlined text-on-surface-variant">chevron_right</span>
            </div>
        </div>

        <!-- About -->
        <div class="px-4 py-6 text-center">
            <p class="text-label-sm text-on-surface-variant">拾光 / Glean v1.0</p>
            <p class="text-label-sm text-on-surface-variant mt-1">AI 驱动的个性化资讯简报</p>
        </div>
    `;
}

// ==================== Article Detail Page ====================

function renderArticleDetailPage(id) {
    const article = GleanData.getArticleById(id);
    if (!article) return `<div class="p-4">文章不存在</div>`;

    const dateStr = new Date(article.publishedAt).toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' });
    const scoreClass = article.scoreTotal >= 8 ? 'score-badge-high' : article.scoreTotal >= 6 ? 'score-badge-mid' : 'score-badge-low';
    const favoriteIcon = article.isFavorited ? 'favorite' : 'favorite_border';
    const favoriteFilled = article.isFavorited ? 'filled' : '';

    return `
        <!-- Sticky Header -->
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center justify-between px-4 py-3">
                ${renderBackButton()}
                <div class="flex items-center gap-2">
                    <button class="detail-favorite-btn p-2 rounded-full hover:bg-surface-container transition-colors">
                        <span class="material-symbols-outlined ${favoriteFilled} text-error text-lg">${favoriteIcon}</span>
                    </button>
                    <button class="detail-export-btn p-2 rounded-full hover:bg-surface-container transition-colors">
                        <span class="material-symbols-outlined text-on-surface-variant text-lg">download</span>
                    </button>
                    <button class="detail-share-btn p-2 rounded-full hover:bg-surface-container transition-colors">
                        <span class="material-symbols-outlined text-on-surface-variant text-lg">share</span>
                    </button>
                </div>
            </div>
        </div>

        <div class="px-6 py-6">
            <!-- Source & Date -->
            <div class="flex items-center gap-3 mb-4">
                <span class="font-mono-code text-label-sm text-on-surface-variant">${article.sourceName}</span>
                <span class="text-outline-variant">|</span>
                <span class="text-label-sm text-on-surface-variant">${dateStr}</span>
            </div>

            <!-- Title -->
            <h1 class="font-serif-display text-headline-md font-semibold text-on-surface leading-tight mb-6">${article.title}</h1>

            <!-- Score -->
            <div class="flex items-center gap-4 mb-8">
                <div class="w-16 h-16 rounded-full border-2 ${scoreClass} flex items-center justify-center">
                    <span class="text-headline-sm font-bold">${article.scoreTotal.toFixed(1)}</span>
                </div>
                <div>
                    <div class="text-label-md font-semibold text-on-surface">内容质量评分</div>
                    <div class="text-body-sm text-on-surface-variant mt-1">
                        来源可信度 ${article.scoreCredibility.toFixed(1)} · 信息密度 ${article.scoreDensity.toFixed(1)}
                    </div>
                    <div class="text-label-sm text-on-surface-variant mt-0.5">
                        ${article.scoreMode === 'llm' ? 'LLM 评分' : '本地规则评分'}
                    </div>
                </div>
            </div>

            <!-- Summary Points -->
            <div class="mb-8">
                <h2 class="text-label-md font-semibold text-on-surface mb-3">核心要点</h2>
                <div class="space-y-3">
                    ${article.summaryPoints.map((point, i) => `
                        <div class="flex items-start gap-3">
                            <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center text-label-sm font-semibold">${i + 1}</span>
                            <p class="text-body-md text-on-surface leading-relaxed">${point}</p>
                        </div>
                    `).join('')}
                </div>
            </div>

            <!-- Content -->
            <div class="mb-8">
                <h2 class="text-label-md font-semibold text-on-surface mb-3">正文</h2>
                <div class="text-body-md text-on-surface-variant leading-relaxed space-y-4">
                    <p>${article.content}</p>
                </div>
            </div>

            <!-- Original Link -->
            <a href="${article.url}" target="_blank" class="inline-flex items-center gap-2 px-4 py-3 rounded-full border border-primary text-primary text-label-md font-semibold hover:bg-primary-container transition-colors">
                <span class="material-symbols-outlined text-base">open_in_new</span>
                <span>阅读原文</span>
            </a>
        </div>
    `;
}

// ==================== Feed Select Page ====================

function renderFeedSelectPage() {
    const feeds = GleanData.getFeeds();
    const enabledCount = feeds.filter(f => f.isEnabled).length;

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center justify-between px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">数据源</h1>
                <button class="add-feed-btn flex items-center gap-1 text-body-md text-primary">
                    <span class="material-symbols-outlined">add</span>
                </button>
            </div>
        </div>

        <div class="px-4 py-2">
            <div class="text-label-sm text-on-surface-variant mb-4">已启用 ${enabledCount} 个数据源</div>
            <div class="space-y-2">
                ${feeds.map(feed => `
                    <div class="flex items-center gap-4 p-4 rounded-xl bg-surface-container-low">
                        <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-surface-container-high flex items-center justify-center text-label-md font-semibold text-on-surface">
                            ${feed.icon}
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="text-body-md font-medium text-on-surface">${feed.name}</div>
                            <div class="text-body-sm text-on-surface-variant line-clamp-1">${feed.description}</div>
                        </div>
                        <label class="toggle-switch">
                            <input type="checkbox" class="feed-toggle" data-id="${feed.id}" ${feed.isEnabled ? 'checked' : ''}>
                            <span class="toggle-slider"></span>
                        </label>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

// ==================== Feed Add Page ====================

function renderFeedAddPage() {
    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">添加数据源</h1>
            </div>
        </div>

        <div class="px-4 py-6 space-y-6">
            <!-- Search -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-2 block">搜索数据源</label>
                <div class="flex gap-2">
                    <input type="text" id="feed-search" placeholder="输入 RSS 地址或关键词" class="flex-1 py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    <button class="search-feeds-btn px-4 py-3 bg-primary text-on-primary rounded-xl text-label-md font-semibold">
                        <span class="material-symbols-outlined">search</span>
                    </button>
                </div>
            </div>

            <!-- Categories -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">推荐源</label>
                <div class="space-y-2">
                    ${['科技', '商业', '设计', '文化'].map(cat => `
                        <div class="p-4 rounded-xl bg-surface-container-low border border-outline-variant/30">
                            <div class="text-body-md font-semibold text-on-surface mb-2">${cat}</div>
                            <div class="flex flex-wrap gap-2">
                                ${GleanData.feeds.filter(f => f.category === cat && !f.isEnabled).map(f => `
                                    <button class="px-3 py-1.5 rounded-full border border-outline text-label-sm text-on-surface-variant hover:bg-surface-container transition-colors">
                                        + ${f.name}
                                    </button>
                                `).join('') || `<span class="text-body-sm text-on-surface-variant">暂无推荐</span>`}
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>

            <!-- OPML Import -->
            <button class="import-opml-btn w-full py-4 border-2 border-dashed border-outline-variant rounded-xl text-body-md text-on-surface-variant hover:border-primary hover:text-primary transition-colors">
                <span class="material-symbols-outlined inline-block mr-2">upload_file</span>
                导入 OPML 文件
            </button>
        </div>
    `;
}

// ==================== Briefing Config Page ====================

function renderBriefingConfigPage() {
    const config = GleanData.userConfig;

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">简报配置</h1>
            </div>
        </div>

        <div class="px-4 py-6 space-y-8">
            <!-- Categories -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">关注方向</label>
                <div class="flex flex-wrap gap-2">
                    ${['科技', '商业', '政治', '社会', '娱乐', '体育'].map(cat => `
                        <label class="flex items-center gap-2 px-4 py-2 rounded-full border border-outline-variant cursor-pointer hover:bg-surface-container transition-colors ${config.categories.includes(cat) ? 'bg-primary text-on-primary border-primary' : 'bg-surface-container-low text-on-surface'}">
                            <input type="checkbox" class="category-checkbox hidden" value="${cat}" ${config.categories.includes(cat) ? 'checked' : ''}>
                            <span class="text-body-sm font-medium">${cat}</span>
                        </label>
                    `).join('')}
                </div>
            </div>

            <!-- Daily Count -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">每日精选数量</label>
                <div class="grid grid-cols-4 gap-3">
                    ${[10, 20, 30, 50].map(count => `
                        <button class="count-selector py-3 rounded-xl text-body-md font-medium transition-colors ${count === config.dailyCount ? 'bg-primary text-on-primary' : 'bg-surface-container-high text-on-surface'}" data-count="${count}">
                            ${count}
                        </button>
                    `).join('')}
                </div>
            </div>

            <!-- Domestic Ratio -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">国内外比例</label>
                <div class="flex items-center gap-3">
                    <span class="text-body-sm text-on-surface-variant">国内</span>
                    <input type="range" id="domestic-ratio" min="0" max="100" value="${Math.round(config.domesticRatio * 100)}" class="flex-1">
                    <span class="text-body-sm text-on-surface-variant">国外</span>
                </div>
                <div class="text-center text-label-sm text-on-surface-variant mt-2" id="domestic-ratio-value">${Math.round(config.domesticRatio * 100)}%</div>
            </div>

            <!-- Push Time -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">推送时间</label>
                <input type="time" id="push-time" value="${config.pushTime}" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
            </div>
        </div>
    `;
}

// ==================== LLM Config Page ====================

function renderLLMConfigPage() {
    const config = GleanData.llmConfig;

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">AI 设置</h1>
            </div>
        </div>

        <div class="px-4 py-6 space-y-6">
            <!-- Provider -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-2 block">提供商</label>
                <select id="llm-provider" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    <option value="mimo" ${config.provider === 'mimo' ? 'selected' : ''}>mimo</option>
                    <option value="openai" ${config.provider === 'openai' ? 'selected' : ''}>OpenAI</option>
                    <option value="deepseek" ${config.provider === 'deepseek' ? 'selected' : ''}>DeepSeek</option>
                    <option value="custom" ${config.provider === 'custom' ? 'selected' : ''}>自定义</option>
                </select>
            </div>

            <!-- API Key -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-2 block">API Key</label>
                <input type="password" id="llm-api-key" value="${config.apiKey}" placeholder="输入您的 API Key" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
            </div>

            <!-- Model -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-2 block">模型</label>
                <select id="llm-model" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    <option value="gpt-4o" ${config.model === 'gpt-4o' ? 'selected' : ''}>gpt-4o</option>
                    <option value="gpt-4o-mini" ${config.model === 'gpt-4o-mini' ? 'selected' : ''}>gpt-4o-mini</option>
                </select>
            </div>

            <!-- Base URL -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-2 block">Base URL</label>
                <input type="text" id="llm-base-url" value="${config.baseUrl}" placeholder="https://api.openai.com/v1" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
            </div>

            <!-- Test Connection -->
            <button class="test-connection-btn w-full py-3 border border-primary text-primary rounded-full text-label-md font-semibold hover:bg-primary-container transition-colors">
                测试连接
            </button>

            <!-- Save -->
            <button class="save-llm-btn w-full py-3 bg-primary text-on-primary rounded-full text-label-md font-semibold hover:bg-ink-blue transition-colors shadow-ambient">
                保存配置
            </button>
        </div>
    `;
}

// ==================== Data Management Page ====================

function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function renderDataManagementPage() {
    const stats = GleanData.getStorageStats();
    const usedStr = formatBytes(stats.totalSize);
    const maxStr = formatBytes(stats.maxSize);

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">数据管理</h1>
            </div>
        </div>

        <div class="px-4 py-6 space-y-6">
            <!-- Storage Info -->
            <div class="p-4 rounded-xl bg-surface-container-low">
                <div class="flex items-center justify-between mb-3">
                    <div class="text-label-md font-semibold text-on-surface">存储空间</div>
                    <span class="text-label-sm text-on-surface-variant">${usedStr} / ${maxStr}</span>
                </div>
                <div class="flex items-center gap-3 mb-4">
                    <div class="flex-1 h-2.5 bg-surface-container-high rounded-full overflow-hidden">
                        <div class="h-full rounded-full transition-all duration-500 ${stats.usedPercent > 80 ? 'bg-error' : stats.usedPercent > 50 ? 'bg-golden-hour' : 'bg-primary'}" style="width: ${Math.max(stats.usedPercent, 1)}%"></div>
                    </div>
                    <span class="text-label-sm font-medium ${stats.usedPercent > 80 ? 'text-error' : 'text-on-surface'}">${stats.usedPercent}%</span>
                </div>
                <!-- Breakdown -->
                <div class="grid grid-cols-2 gap-2 text-label-sm">
                    <div class="flex justify-between py-1.5 px-3 rounded-lg bg-surface-container-high">
                        <span class="text-on-surface-variant">文章</span>
                        <span class="text-on-surface font-medium">${stats.counts.articles} 篇 · ${formatBytes(stats.breakdown.articles)}</span>
                    </div>
                    <div class="flex justify-between py-1.5 px-3 rounded-lg bg-surface-container-high">
                        <span class="text-on-surface-variant">简报</span>
                        <span class="text-on-surface font-medium">${stats.counts.briefings} 个 · ${formatBytes(stats.breakdown.briefings)}</span>
                    </div>
                    <div class="flex justify-between py-1.5 px-3 rounded-lg bg-surface-container-high">
                        <span class="text-on-surface-variant">数据源</span>
                        <span class="text-on-surface font-medium">${stats.counts.feeds} 个 · ${formatBytes(stats.breakdown.feeds)}</span>
                    </div>
                    <div class="flex justify-between py-1.5 px-3 rounded-lg bg-surface-container-high">
                        <span class="text-on-surface-variant">日志</span>
                        <span class="text-on-surface font-medium">${stats.counts.logs} 条 · ${formatBytes(stats.breakdown.logs)}</span>
                    </div>
                </div>
            </div>

            <!-- Export -->
            <div class="space-y-3">
                <div class="text-label-md font-semibold text-on-surface">导出数据</div>
                <button class="export-json-btn w-full flex items-center gap-3 p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                    <span class="material-symbols-outlined text-on-surface-variant">code</span>
                    <div class="flex-1 text-left">
                        <div class="text-body-md font-medium">导出 JSON</div>
                        <div class="text-body-sm text-on-surface-variant">结构化数据，适合备份和迁移</div>
                    </div>
                    <span class="material-symbols-outlined text-on-surface-variant">download</span>
                </button>
                <button class="export-md-btn w-full flex items-center gap-3 p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                    <span class="material-symbols-outlined text-on-surface-variant">description</span>
                    <div class="flex-1 text-left">
                        <div class="text-body-md font-medium">导出 Markdown</div>
                        <div class="text-body-sm text-on-surface-variant">适合阅读和人工整理</div>
                    </div>
                    <span class="material-symbols-outlined text-on-surface-variant">download</span>
                </button>
            </div>

            <!-- Clear Data -->
            <div class="pt-4 border-t border-outline-variant/30 space-y-3">
                <div class="text-label-md font-semibold text-on-surface">清理数据</div>
                <button class="clear-articles-btn w-full flex items-center justify-between p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                    <div class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-on-surface-variant">article</span>
                        <div class="text-left">
                            <div class="text-body-md font-medium">清除文章</div>
                            <div class="text-body-sm text-on-surface-variant">保留配置和日志</div>
                        </div>
                    </div>
                    <span class="material-symbols-outlined text-error">delete</span>
                </button>
                <button class="clear-logs-btn w-full flex items-center justify-between p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                    <div class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-on-surface-variant">history</span>
                        <div class="text-left">
                            <div class="text-body-md font-medium">清除日志</div>
                            <div class="text-body-sm text-on-surface-variant">保留文章和数据源</div>
                        </div>
                    </div>
                    <span class="material-symbols-outlined text-error">delete</span>
                </button>
                <button class="clear-data-btn w-full py-3 mt-2 border border-error text-error rounded-full text-label-md font-semibold hover:bg-error-container transition-colors">
                    清除所有数据
                </button>
            </div>
        </div>
    `;
}

// ==================== Fetch Settings Page ====================

function renderFetchSettingsPage() {
    const config = GleanData.userConfig;

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">采集设置</h1>
            </div>
        </div>

        <div class="px-4 py-6 space-y-6">
            <!-- Fetch Interval -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">采集间隔</label>
                <select id="fetch-interval" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    <option value="1" ${config.fetchInterval === 1 ? 'selected' : ''}>每小时</option>
                    <option value="2" ${config.fetchInterval === 2 ? 'selected' : ''}>每 2 小时</option>
                    <option value="4" ${config.fetchInterval === 4 ? 'selected' : ''}>每 4 小时</option>
                    <option value="0" ${config.fetchInterval === 0 ? 'selected' : ''}>手动</option>
                </select>
            </div>

            <!-- WiFi Only -->
            <div class="flex items-center justify-between p-4 rounded-xl bg-surface-container-low">
                <div>
                    <div class="text-body-md font-medium text-on-surface">仅 WiFi 采集</div>
                    <div class="text-body-sm text-on-surface-variant">避免使用移动数据</div>
                </div>
                <label class="toggle-switch">
                    <input type="checkbox" id="wifi-only" ${config.wifiOnly ? 'checked' : ''}>
                    <span class="toggle-slider"></span>
                </label>
            </div>

            <!-- Retention Days -->
            <div>
                <label class="text-label-md font-semibold text-on-surface mb-3 block">数据保留天数</label>
                <select id="retention-days" class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary">
                    <option value="7" ${config.retentionDays === 7 ? 'selected' : ''}>7 天</option>
                    <option value="14" ${config.retentionDays === 14 ? 'selected' : ''}>14 天</option>
                    <option value="30" ${config.retentionDays === 30 ? 'selected' : ''}>30 天</option>
                    <option value="90" ${config.retentionDays === 90 ? 'selected' : ''}>90 天</option>
                </select>
            </div>
        </div>
    `;
}

// ==================== Execution Logs Page ====================

function renderExecutionLogsPage() {
    const logs = GleanData.getExecutionLogs('all');

    return `
        <div class="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 safe-top">
            <div class="flex items-center gap-3 px-4 py-3">
                ${renderBackButton()}
                <h1 class="text-headline-sm font-sans-body font-semibold">执行记录</h1>
            </div>
        </div>

        <!-- Filter Tabs -->
        <div class="sticky top-[57px] z-30 bg-surface/95 backdrop-blur-md border-b border-outline-variant/30 px-4 py-3">
            <div class="flex items-center gap-2">
                <button class="log-filter-btn px-4 py-2 rounded-full text-label-sm font-medium bg-primary text-on-primary transition-colors" data-filter="all">
                    全部
                </button>
                <button class="log-filter-btn px-4 py-2 rounded-full text-label-sm font-medium bg-surface-container-high text-on-surface-variant transition-colors" data-filter="fetch">
                    采集
                </button>
                <button class="log-filter-btn px-4 py-2 rounded-full text-label-sm font-medium bg-surface-container-high text-on-surface-variant transition-colors" data-filter="score">
                    评分
                </button>
                <button class="log-filter-btn px-4 py-2 rounded-full text-label-sm font-medium bg-surface-container-high text-on-surface-variant transition-colors" data-filter="briefing">
                    简报
                </button>
            </div>
        </div>

        <div id="logs-list" class="divide-y divide-outline-variant/30">
            ${logs.length > 0 ? logs.map(log => renderLogItem(log)).join('') : `
                <div class="flex flex-col items-center justify-center py-16 px-6">
                    <span class="material-symbols-outlined text-6xl text-outline-variant mb-4">history</span>
                    <p class="text-body-md text-on-surface-variant text-center">暂无记录</p>
                </div>
            `}
        </div>
    `;
}

// ==================== Briefing Generate Page ====================

function renderBriefingGeneratePage() {
    return `
        <div class="min-h-screen flex flex-col items-center justify-center px-6 safe-top safe-bottom">
            <div class="text-center mb-12">
                <span class="material-symbols-outlined text-6xl text-golden-hour mb-4">auto_awesome</span>
                <h2 class="text-headline-md font-sans-body font-semibold text-on-surface mb-2">正在生成简报</h2>
                <p class="text-body-md text-on-surface-variant">AI 正在为您筛选和整理今日资讯</p>
            </div>

            <!-- Progress -->
            <div class="w-full max-w-xs mb-8">
                <div class="flex items-center justify-between mb-2">
                    <span class="text-label-sm text-on-surface-variant" id="generate-step-number">Step 1 of 3</span>
                    <span class="text-label-sm font-medium text-on-surface" id="generate-step-name">扫描资讯源</span>
                </div>
                <div class="h-1 bg-soft-grey rounded-full overflow-hidden">
                    <div id="generate-progress" class="h-full progress-gradient rounded-full transition-all duration-500" style="width: 0%"></div>
                </div>
            </div>

            <!-- Stats -->
            <div class="grid grid-cols-3 gap-4 w-full max-w-xs">
                <div class="text-center p-3 rounded-xl bg-surface-container-low">
                    <div class="text-headline-sm font-bold text-on-surface">42</div>
                    <div class="text-label-sm text-on-surface-variant">已扫描</div>
                </div>
                <div class="text-center p-3 rounded-xl bg-surface-container-low">
                    <div class="text-headline-sm font-bold text-on-surface">20</div>
                    <div class="text-label-sm text-on-surface-variant">已精选</div>
                </div>
                <div class="text-center p-3 rounded-xl bg-surface-container-low">
                    <div class="text-headline-sm font-bold text-golden-hour">9.8</div>
                    <div class="text-label-sm text-on-surface-variant">最高分</div>
                </div>
            </div>
        </div>
    `;
}

// ==================== App Initialization ====================

document.addEventListener('DOMContentLoaded', () => {
    GleanRouter.init();
});
