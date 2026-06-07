// Router & Navigation for Glean App
const GleanRouter = {
    currentPage: null,
    currentFilter: 'all',
    currentSort: 'score',
    onboardingStep: 0,

    // Page registry
    pages: {
        welcome: () => renderWelcomePage(),
        onboarding: () => renderOnboardingPage(),
        home: () => renderHomePage(),
        briefing: () => renderBriefingPage(),
        favorites: () => renderFavoritesPage(),
        settings: () => renderSettingsPage(),
        'article-detail': (id) => renderArticleDetailPage(id),
        'feed-select': () => renderFeedSelectPage(),
        'feed-add': () => renderFeedAddPage(),
        'briefing-config': () => renderBriefingConfigPage(),
        'llm-config': () => renderLLMConfigPage(),
        'data-management': () => renderDataManagementPage(),
        'fetch-settings': () => renderFetchSettingsPage(),
        'execution-logs': () => renderExecutionLogsPage(),
        'briefing-generate': () => renderBriefingGeneratePage(),
    },

    // Navigate to a page
    navigate(page, params = {}) {
        const mainContent = document.getElementById('main-content');
        const bottomNav = document.getElementById('bottom-nav');

        // Update current page
        this.currentPage = page;

        // Show/hide bottom nav
        const navPages = ['home', 'briefing', 'favorites', 'settings'];
        if (navPages.includes(page)) {
            bottomNav.classList.remove('hidden');
            this.updateNavActive(page);
        } else {
            bottomNav.classList.add('hidden');
        }

        // Render page content
        const renderFn = this.pages[page];
        if (renderFn) {
            mainContent.innerHTML = renderFn(params);
            mainContent.classList.add('page-enter');
            setTimeout(() => mainContent.classList.remove('page-enter'), 300);

            // Scroll to top
            window.scrollTo(0, 0);

            // Initialize page-specific handlers
            this.initPageHandlers(page, params);

            // Apply stagger animation to list items
            setTimeout(() => {
                if (typeof animateStagger === 'function') {
                    animateStagger('.article-card', 'animate-fade-in-up', 40);
                    animateStagger('.briefing-article-card', 'animate-fade-in-up', 40);
                    animateStagger('.settings-row', 'animate-fade-in-up', 30);
                }
            }, 50);
        }
    },

    // Update bottom nav active state
    updateNavActive(page) {
        // Mobile bottom nav
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('nav-item-active');
            const icon = item.querySelector('.nav-icon');
            icon?.classList.remove('bg-surface-container-high');
            if (item.dataset.page === page) {
                item.classList.add('nav-item-active');
                icon?.classList.add('bg-surface-container-high');
            }
        });

        // Desktop sidebar nav
        document.querySelectorAll('.sidebar-nav-item').forEach(item => {
            item.classList.remove('bg-primary-container', 'text-on-primary-container');
            item.classList.add('text-on-surface-variant', 'hover:bg-surface-container');
            if (item.dataset.page === page) {
                item.classList.remove('text-on-surface-variant', 'hover:bg-surface-container');
                item.classList.add('bg-primary-container', 'text-on-primary-container');
            }
        });
    },

    // Initialize page-specific event handlers
    initPageHandlers(page, params) {
        switch (page) {
            case 'home':
                this.initHomeHandlers();
                break;
            case 'briefing':
                this.initBriefingHandlers();
                break;
            case 'favorites':
                this.initFavoritesHandlers();
                break;
            case 'settings':
                this.initSettingsHandlers();
                break;
            case 'article-detail':
                this.initArticleDetailHandlers(params.id);
                break;
            case 'feed-select':
                this.initFeedSelectHandlers();
                break;
            case 'feed-add':
                this.initFeedAddHandlers();
                break;
            case 'briefing-config':
                this.initBriefingConfigHandlers();
                break;
            case 'llm-config':
                this.initLLMConfigHandlers();
                break;
            case 'data-management':
                this.initDataManagementHandlers();
                break;
            case 'fetch-settings':
                this.initFetchSettingsHandlers();
                break;
            case 'execution-logs':
                this.initExecutionLogsHandlers();
                break;
            case 'briefing-generate':
                this.initBriefingGenerateHandlers();
                break;
            case 'welcome':
                this.initWelcomeHandlers();
                break;
            case 'onboarding':
                this.initOnboardingHandlers();
                break;
        }
    },

    // Home page handlers
    initHomeHandlers() {
        // Pull to refresh
        this.initPullToRefresh('article-list');

        // Filter tabs
        document.querySelectorAll('.filter-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const filter = e.currentTarget.dataset.filter;
                this.currentFilter = filter;

                // Update active state
                document.querySelectorAll('.filter-tab').forEach(t => {
                    t.classList.remove('bg-primary', 'text-on-primary');
                    t.classList.add('bg-surface-container-high', 'text-on-surface-variant');
                });
                e.currentTarget.classList.remove('bg-surface-container-high', 'text-on-surface-variant');
                e.currentTarget.classList.add('bg-primary', 'text-on-primary');

                // Refresh article list
                this.refreshArticleList();
            });
        });

        // Sort toggle
        document.querySelector('.sort-toggle')?.addEventListener('click', () => {
            this.currentSort = this.currentSort === 'score' ? 'time' : 'score';
            const sortLabel = this.currentSort === 'score' ? '价值分' : '时间';
            document.querySelector('.sort-toggle span:last-child').textContent = sortLabel;
            this.refreshArticleList();
        });

        // Article card clicks
        document.querySelectorAll('.article-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.closest('.favorite-btn') || e.target.closest('.share-btn')) return;
                const id = card.dataset.id;
                this.navigate('article-detail', { id });
            });
        });

        // Favorite buttons
        document.querySelectorAll('.favorite-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = btn.dataset.id;
                const isFav = GleanData.toggleFavorite(id);
                const icon = btn.querySelector('.material-symbols-outlined');
                icon.textContent = isFav ? 'favorite' : 'favorite_border';
                icon.classList.toggle('filled', isFav);
                icon.classList.toggle('text-error', isFav);
                icon.classList.add('heart-animate');
                setTimeout(() => icon.classList.remove('heart-animate'), 300);
            });
        });
    },

    // Pull to refresh implementation
    initPullToRefresh(listId) {
        const list = document.getElementById(listId);
        if (!list) return;

        let startY = 0;
        let currentY = 0;
        let isPulling = false;
        let ptrIndicator = null;

        const container = list.parentElement || list;

        container.addEventListener('touchstart', (e) => {
            if (window.scrollY <= 0) {
                startY = e.touches[0].clientY;
                isPulling = true;
            }
        }, { passive: true });

        container.addEventListener('touchmove', (e) => {
            if (!isPulling || window.scrollY > 0) return;

            currentY = e.touches[0].clientY;
            const diff = currentY - startY;

            if (diff > 0 && diff < 120) {
                if (!ptrIndicator) {
                    ptrIndicator = document.createElement('div');
                    ptrIndicator.className = 'ptr-indicator flex items-center justify-center py-3 text-on-surface-variant';
                    ptrIndicator.innerHTML = `<span class="material-symbols-outlined text-2xl transition-transform duration-200" style="transform: rotate(${Math.min(diff * 1.5, 180)}deg)">refresh</span>`;
                    container.insertBefore(ptrIndicator, list);
                }
                ptrIndicator.querySelector('span').style.transform = `rotate(${Math.min(diff * 1.5, 180)}deg)`;
            }
        }, { passive: true });

        container.addEventListener('touchend', () => {
            if (!isPulling) return;
            isPulling = false;

            const diff = currentY - startY;
            if (diff > 80 && ptrIndicator) {
                ptrIndicator.innerHTML = renderSpinner('md', 'text-primary');
                ptrIndicator.classList.add('refreshing');

                // Simulate refresh
                setTimeout(() => {
                    ptrIndicator?.remove();
                    ptrIndicator = null;
                    this.showToast('已刷新', 'success');
                    this.refreshArticleList();
                }, 1200);
            } else {
                ptrIndicator?.remove();
                ptrIndicator = null;
            }

            startY = 0;
            currentY = 0;
        });
    },

    // Refresh article list (for filter/sort changes)
    refreshArticleList() {
        const container = document.getElementById('article-list');
        if (!container) return;

        let articles = GleanData.getArticles(this.currentFilter);
        if (this.currentSort === 'time') {
            articles.sort((a, b) => b.publishedAt - a.publishedAt);
        }

        if (articles.length === 0) {
            const emptyType = this.currentFilter === 'favorited' ? 'favorites' : 'inbox';
            container.innerHTML = typeof renderEmptyState === 'function'
                ? renderEmptyState(emptyType)
                : `<div class="p-4 text-center text-on-surface-variant">暂无内容</div>`;
        } else {
            container.innerHTML = articles.map(article => renderArticleCard(article, { animate: false })).join('');

            // Apply stagger animation
            setTimeout(() => {
                if (typeof animateStagger === 'function') {
                    animateStagger('.article-card', 'animate-fade-in-up', 30);
                }
            }, 10);
        }

        // Re-attach handlers
        document.querySelectorAll('.article-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.closest('.favorite-btn') || e.target.closest('.share-btn')) return;
                const id = card.dataset.id;
                this.navigate('article-detail', { id });
            });
        });

        document.querySelectorAll('.favorite-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = btn.dataset.id;
                const isFav = GleanData.toggleFavorite(id);
                const icon = btn.querySelector('.material-symbols-outlined');
                icon.textContent = isFav ? 'favorite' : 'favorite_border';
                icon.classList.toggle('filled', isFav);
                icon.classList.toggle('text-error', isFav);
                icon.classList.add('heart-animate');
                setTimeout(() => icon.classList.remove('heart-animate'), 300);
            });
        });
    },

    // Briefing page handlers
    initBriefingHandlers() {
        document.querySelector('.regenerate-btn')?.addEventListener('click', () => {
            this.navigate('briefing-generate');
        });

        document.querySelector('.export-briefing-btn')?.addEventListener('click', () => {
            this.showExportModal('briefing', 'b1');
        });

        // Article card clicks in briefing
        document.querySelectorAll('.briefing-article-card').forEach(card => {
            card.addEventListener('click', () => {
                const id = card.dataset.id;
                this.navigate('article-detail', { id });
            });
        });
    },

    // Favorites page handlers
    initFavoritesHandlers() {
        document.querySelectorAll('.article-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.closest('.favorite-btn')) return;
                const id = card.dataset.id;
                this.navigate('article-detail', { id });
            });
        });

        document.querySelectorAll('.favorite-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = btn.dataset.id;
                const isFav = GleanData.toggleFavorite(id);
                if (!isFav) {
                    // Remove card from favorites list
                    const card = btn.closest('.article-card');
                    card.style.opacity = '0';
                    card.style.transform = 'translateX(100%)';
                    setTimeout(() => card.remove(), 300);
                }
            });
        });
    },

    // Settings page handlers
    initSettingsHandlers() {
        document.querySelectorAll('.settings-row').forEach(row => {
            row.addEventListener('click', (e) => {
                const page = row.dataset.page;
                if (page) {
                    this.navigate(page);
                }
            });
        });
    },

    // Article detail handlers
    initArticleDetailHandlers(id) {
        // Mark as read
        GleanData.markAsRead(id);

        // Favorite button
        document.querySelector('.detail-favorite-btn')?.addEventListener('click', () => {
            const isFav = GleanData.toggleFavorite(id);
            const icon = document.querySelector('.detail-favorite-btn .material-symbols-outlined');
            icon.textContent = isFav ? 'favorite' : 'favorite_border';
            icon.classList.toggle('filled', isFav);
        });

        // Export button
        document.querySelector('.detail-export-btn')?.addEventListener('click', () => {
            this.showExportModal('article', id);
        });

        // Share button
        document.querySelector('.detail-share-btn')?.addEventListener('click', () => {
            const article = GleanData.getArticleById(id);
            if (navigator.share) {
                navigator.share({
                    title: article.title,
                    url: article.url,
                });
            } else {
                this.showToast('分享功能需要系统支持');
            }
        });

        // Back button
        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('home');
        });
    },

    // Feed select handlers
    initFeedSelectHandlers() {
        document.querySelectorAll('.feed-toggle').forEach(toggle => {
            toggle.addEventListener('change', (e) => {
                const feedId = e.target.dataset.id;
                GleanData.toggleFeed(feedId);
            });
        });

        document.querySelector('.add-feed-btn')?.addEventListener('click', () => {
            this.navigate('feed-add');
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    // Feed add handlers
    initFeedAddHandlers() {
        document.querySelector('.search-feeds-btn')?.addEventListener('click', () => {
            const query = document.getElementById('feed-search').value;
            if (query) {
                this.showToast(`搜索: ${query}`);
            }
        });

        document.querySelector('.import-opml-btn')?.addEventListener('click', () => {
            this.showToast('OPML 导入功能开发中');
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('feed-select');
        });
    },

    // Briefing config handlers
    initBriefingConfigHandlers() {
        // Category checkboxes
        document.querySelectorAll('.category-checkbox').forEach(cb => {
            cb.addEventListener('change', () => {
                const selected = Array.from(document.querySelectorAll('.category-checkbox:checked'))
                    .map(c => c.value);
                GleanData.updateUserConfig({ categories: selected });
            });
        });

        // Daily count selector
        document.querySelectorAll('.count-selector').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.count-selector').forEach(b => {
                    b.classList.remove('bg-primary', 'text-on-primary');
                    b.classList.add('bg-surface-container-high', 'text-on-surface');
                });
                e.currentTarget.classList.remove('bg-surface-container-high', 'text-on-surface');
                e.currentTarget.classList.add('bg-primary', 'text-on-primary');
                GleanData.updateUserConfig({ dailyCount: parseInt(e.currentTarget.dataset.count) });
            });
        });

        // Domestic ratio slider
        document.getElementById('domestic-ratio')?.addEventListener('input', (e) => {
            const value = parseInt(e.target.value) / 100;
            document.getElementById('domestic-ratio-value').textContent = `${Math.round(value * 100)}%`;
            GleanData.updateUserConfig({ domesticRatio: value });
        });

        // Push time
        document.getElementById('push-time')?.addEventListener('change', (e) => {
            GleanData.updateUserConfig({ pushTime: e.target.value });
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    // LLM config handlers
    initLLMConfigHandlers() {
        document.getElementById('llm-provider')?.addEventListener('change', (e) => {
            const provider = e.target.value;
            // Update model options based on provider
            const modelSelect = document.getElementById('llm-model');
            const models = {
                mimo: ['gpt-4o', 'gpt-4o-mini'],
                openai: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo'],
                deepseek: ['deepseek-chat', 'deepseek-coder'],
                custom: ['custom'],
            };
            modelSelect.innerHTML = (models[provider] || []).map(m =>
                `<option value="${m}">${m}</option>`
            ).join('');
        });

        document.querySelector('.test-connection-btn')?.addEventListener('click', () => {
            this.showToast('正在测试连接...');
            setTimeout(() => {
                this.showToast('连接成功', 'success');
            }, 1500);
        });

        document.querySelector('.save-llm-btn')?.addEventListener('click', () => {
            const config = {
                provider: document.getElementById('llm-provider').value,
                apiKey: document.getElementById('llm-api-key').value,
                model: document.getElementById('llm-model').value,
                baseUrl: document.getElementById('llm-base-url').value,
                isConfigured: true,
            };
            GleanData.updateLLMConfig(config);
            this.showToast('配置已保存', 'success');
            this.navigate('settings');
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    // Data management handlers
    initDataManagementHandlers() {
        document.querySelector('.export-json-btn')?.addEventListener('click', () => {
            const data = GleanData.exportAll('json');
            const timestamp = new Date().toISOString().split('T')[0];
            this.downloadFile(data, `glean-backup-${timestamp}.json`, 'application/json');
            this.showToast('JSON 数据已导出', 'success');
        });

        document.querySelector('.export-md-btn')?.addEventListener('click', () => {
            const data = GleanData.exportAll('markdown');
            const timestamp = new Date().toISOString().split('T')[0];
            this.downloadFile(data, `glean-export-${timestamp}.md`, 'text/markdown');
            this.showToast('Markdown 数据已导出', 'success');
        });

        document.querySelector('.clear-articles-btn')?.addEventListener('click', () => {
            if (typeof showConfirmDialog === 'function') {
                showConfirmDialog(
                    '清除文章',
                    '确定要清除所有文章数据吗？收藏和阅读记录也将被删除。',
                    () => {
                        GleanData.clearData('articles');
                        this.showToast('文章已清除', 'success');
                        // Refresh page to update stats
                        setTimeout(() => this.navigate('data-management'), 300);
                    }
                );
            }
        });

        document.querySelector('.clear-logs-btn')?.addEventListener('click', () => {
            if (typeof showConfirmDialog === 'function') {
                showConfirmDialog(
                    '清除日志',
                    '确定要清除所有执行日志吗？',
                    () => {
                        GleanData.clearData('logs');
                        this.showToast('日志已清除', 'success');
                        setTimeout(() => this.navigate('data-management'), 300);
                    }
                );
            }
        });

        document.querySelector('.clear-data-btn')?.addEventListener('click', () => {
            if (typeof showConfirmDialog === 'function') {
                showConfirmDialog(
                    '清除所有数据',
                    '确定要清除所有数据吗？此操作不可恢复。',
                    () => {
                        GleanData.clearData('all');
                        this.showToast('所有数据已清除', 'success');
                        setTimeout(() => this.navigate('data-management'), 300);
                    }
                );
            } else {
                if (confirm('确定要清除所有数据吗？此操作不可恢复。')) {
                    GleanData.clearData('all');
                    this.showToast('数据已清除');
                }
            }
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    // Fetch settings handlers
    initFetchSettingsHandlers() {
        document.getElementById('fetch-interval')?.addEventListener('change', (e) => {
            GleanData.updateUserConfig({ fetchInterval: parseInt(e.target.value) });
        });

        document.getElementById('wifi-only')?.addEventListener('change', (e) => {
            GleanData.updateUserConfig({ wifiOnly: e.target.checked });
        });

        document.getElementById('retention-days')?.addEventListener('change', (e) => {
            GleanData.updateUserConfig({ retentionDays: parseInt(e.target.value) });
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    // Execution logs handlers
    initExecutionLogsHandlers() {
        document.querySelectorAll('.log-filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const filter = e.currentTarget.dataset.filter;
                document.querySelectorAll('.log-filter-btn').forEach(b => {
                    b.classList.remove('bg-primary', 'text-on-primary');
                    b.classList.add('bg-surface-container-high', 'text-on-surface-variant');
                });
                e.currentTarget.classList.remove('bg-surface-container-high', 'text-on-surface-variant');
                e.currentTarget.classList.add('bg-primary', 'text-on-primary');
                this.refreshLogs(filter);
            });
        });

        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.navigate('settings');
        });
    },

    refreshLogs(filter) {
        const container = document.getElementById('logs-list');
        if (!container) return;

        const logs = GleanData.getExecutionLogs(filter);
        container.innerHTML = logs.map(log => renderLogItem(log)).join('');
    },

    // Briefing generate handlers
    initBriefingGenerateHandlers() {
        // Simulate generation progress
        const steps = [
            { name: '扫描资讯源', progress: 33, time: 800 },
            { name: '提炼核心观点', progress: 66, time: 1600 },
            { name: '智能排版生成', progress: 100, time: 2400 },
        ];

        let currentStep = 0;
        const progressBar = document.getElementById('generate-progress');
        const stepName = document.getElementById('generate-step-name');
        const stepNumber = document.getElementById('generate-step-number');

        const interval = setInterval(() => {
            if (currentStep >= steps.length) {
                clearInterval(interval);
                setTimeout(() => {
                    this.navigate('briefing');
                }, 500);
                return;
            }

            const step = steps[currentStep];
            if (progressBar) progressBar.style.width = `${step.progress}%`;
            if (stepName) stepName.textContent = step.name;
            if (stepNumber) stepNumber.textContent = `Step ${currentStep + 1} of 3`;

            currentStep++;
        }, 800);
    },

    // Welcome handlers
    initWelcomeHandlers() {
        document.querySelector('.start-btn')?.addEventListener('click', () => {
            this.navigate('onboarding');
        });
    },

    // Onboarding handlers
    initOnboardingHandlers() {
        const steps = document.querySelectorAll('.onboarding-step');
        const nextBtn = document.querySelector('.onboarding-next-btn');
        const prevBtn = document.querySelector('.onboarding-prev-btn');
        let currentStep = 0;

        const updateStep = () => {
            steps.forEach((step, i) => {
                step.classList.toggle('hidden', i !== currentStep);
            });

            if (prevBtn) {
                prevBtn.classList.toggle('hidden', currentStep === 0);
            }

            if (nextBtn) {
                if (currentStep === steps.length - 1) {
                    nextBtn.textContent = '开始使用';
                } else {
                    nextBtn.textContent = '下一步';
                }
            }
        };

        nextBtn?.addEventListener('click', () => {
            if (currentStep < steps.length - 1) {
                currentStep++;
                updateStep();
            } else {
                GleanData.updateUserConfig({ onboardingDone: true });
                this.navigate('briefing-generate');
            }
        });

        prevBtn?.addEventListener('click', () => {
            if (currentStep > 0) {
                currentStep--;
                updateStep();
            }
        });

        updateStep();
    },

    // Show export modal
    showExportModal(type, id) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/40 z-50 flex items-end justify-center';
        modal.innerHTML = `
            <div class="bg-surface w-full max-w-readable rounded-t-2xl p-6 animate-slide-up">
                <div class="flex items-center justify-between mb-6">
                    <h3 class="text-headline-sm font-sans-body font-semibold">导出</h3>
                    <button class="close-modal-btn material-symbols-outlined text-on-surface-variant">close</button>
                </div>
                <div class="space-y-3">
                    <button class="export-md-btn w-full flex items-center gap-3 p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                        <span class="material-symbols-outlined text-on-surface-variant">description</span>
                        <div class="text-left">
                            <div class="text-body-md font-medium">Markdown</div>
                            <div class="text-body-sm text-on-surface-variant">适合阅读和编辑</div>
                        </div>
                    </button>
                    <button class="export-json-btn w-full flex items-center gap-3 p-4 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors">
                        <span class="material-symbols-outlined text-on-surface-variant">code</span>
                        <div class="text-left">
                            <div class="text-body-md font-medium">JSON</div>
                            <div class="text-body-sm text-on-surface-variant">结构化数据</div>
                        </div>
                    </button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        modal.querySelector('.close-modal-btn').addEventListener('click', () => modal.remove());
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.remove();
        });

        modal.querySelector('.export-md-btn').addEventListener('click', () => {
            let data;
            if (type === 'article') {
                data = GleanData.exportArticle(id, 'markdown');
                this.downloadFile(data, `article-${id}.md`, 'text/markdown');
            } else {
                data = GleanData.exportBriefing(id, 'markdown');
                this.downloadFile(data, `briefing-${id}.md`, 'text/markdown');
            }
            modal.remove();
            this.showToast('已导出 Markdown');
        });

        modal.querySelector('.export-json-btn').addEventListener('click', () => {
            let data;
            if (type === 'article') {
                data = GleanData.exportArticle(id, 'json');
                this.downloadFile(data, `article-${id}.json`, 'application/json');
            } else {
                data = GleanData.exportBriefing(id, 'json');
                this.downloadFile(data, `briefing-${id}.json`, 'application/json');
            }
            modal.remove();
            this.showToast('已导出 JSON');
        });
    },

    // Download file helper
    downloadFile(content, filename, mimeType) {
        const blob = new Blob([content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    },

    // Show toast notification
    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        const bgColor = type === 'success' ? 'bg-inverse-surface' : 'bg-inverse-surface';
        const textColor = 'text-inverse-on-surface';

        toast.className = `fixed bottom-24 left-1/2 -translate-x-1/2 ${bgColor} ${textColor} px-6 py-3 rounded-full text-body-sm font-medium shadow-modal z-50 animate-fade-in`;
        toast.textContent = message;

        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transition = 'opacity 0.3s';
            setTimeout(() => toast.remove(), 300);
        }, 2500);
    },

    // Initialize app
    init() {
        // Setup bottom nav click handlers (mobile)
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => {
                const page = item.dataset.page;
                this.navigate(page);
            });
        });

        // Setup sidebar nav click handlers (desktop)
        document.querySelectorAll('.sidebar-nav-item').forEach(item => {
            item.addEventListener('click', () => {
                const page = item.dataset.page;
                this.navigate(page);
            });
        });

        // Setup gesture back (swipe from left edge, mobile only)
        this.initGestureBack();

        // Check onboarding status
        if (!GleanData.userConfig.onboardingDone) {
            this.navigate('welcome');
        } else {
            this.navigate('home');
        }
    },

    // Gesture back navigation (swipe from left edge)
    initGestureBack() {
        let startX = 0;
        let startY = 0;
        let isGesturing = false;
        const edgeThreshold = 24; // px from left edge

        document.addEventListener('touchstart', (e) => {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
            isGesturing = startX <= edgeThreshold;
        }, { passive: true });

        document.addEventListener('touchmove', (e) => {
            if (!isGesturing) return;

            const currentX = e.touches[0].clientX;
            const diffX = currentX - startX;
            const diffY = Math.abs(e.touches[0].clientY - startY);

            // Only trigger if horizontal swipe is dominant
            if (diffX > 40 && diffY < diffX * 0.5) {
                const hint = document.querySelector('.gesture-back-hint');
                if (hint) hint.classList.add('visible');
            }
        }, { passive: true });

        document.addEventListener('touchend', (e) => {
            if (!isGesturing) return;
            isGesturing = false;

            const endX = e.changedTouches[0].clientX;
            const diffX = endX - startX;
            const diffY = Math.abs(e.changedTouches[0].clientY - startY);

            const hint = document.querySelector('.gesture-back-hint');
            if (hint) hint.classList.remove('visible');

            // Trigger back if swiped far enough horizontally
            if (diffX > 80 && diffY < diffX * 0.5) {
                this.handleGestureBack();
            }
        });
    },

    // Handle gesture back navigation
    handleGestureBack() {
        const navPages = ['home', 'briefing', 'favorites', 'settings'];
        const subPages = ['article-detail', 'feed-select', 'feed-add', 'briefing-config', 'llm-config', 'data-management', 'fetch-settings', 'execution-logs'];

        if (subPages.includes(this.currentPage)) {
            // Go back to settings or home based on context
            if (this.currentPage === 'article-detail') {
                this.navigate('home');
            } else {
                this.navigate('settings');
            }
        }
    },
};
