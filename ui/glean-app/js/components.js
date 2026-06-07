// Glean App - Shared Component Library
// Reusable UI components following DESIGN.md design system

// ==================== Button Variants ====================

/**
 * Render a button with specified variant
 * @param {string} text - Button text
 * @param {Object} options - Button options
 * @param {string} options.variant - 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline'
 * @param {string} options.size - 'sm' | 'md' | 'lg'
 * @param {string} options.icon - Material Symbols icon name
 * @param {string} options.iconPosition - 'left' | 'right'
 * @param {string} options.className - Additional CSS classes
 * @param {string} options.type - 'button' | 'submit'
 * @param {boolean} options.disabled - Whether button is disabled
 * @param {string} options.id - Button ID
 * @param {string} options.dataset - Data attributes object
 */
function renderButton(text, options = {}) {
    const {
        variant = 'primary',
        size = 'md',
        icon = '',
        iconPosition = 'left',
        className = '',
        type = 'button',
        disabled = false,
        id = '',
        dataset = {}
    } = options;

    const variantClasses = {
        primary: 'bg-primary text-on-primary hover:bg-ink-blue shadow-ambient',
        secondary: 'bg-secondary-container text-on-secondary-container hover:bg-secondary-fixed',
        ghost: 'bg-transparent text-on-surface-variant hover:bg-surface-container',
        danger: 'bg-error text-on-error hover:bg-error-container hover:text-on-error-container',
        outline: 'border border-outline text-on-surface hover:bg-surface-container'
    };

    const sizeClasses = {
        sm: 'px-3 py-1.5 text-label-sm',
        md: 'px-4 py-2.5 text-label-md',
        lg: 'px-6 py-3.5 text-body-md'
    };

    const baseClasses = 'inline-flex items-center justify-center gap-2 rounded-full font-semibold transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed';

    const iconHtml = icon ? `<span class="material-symbols-outlined ${size === 'sm' ? 'text-base' : 'text-lg'}">${icon}</span>` : '';
    const contentHtml = iconPosition === 'left'
        ? `${iconHtml}${text ? `<span>${text}</span>` : ''}`
        : `${text ? `<span>${text}</span>` : ''}${iconHtml}`;

    const dataAttrs = Object.entries(dataset).map(([k, v]) => `data-${k}="${v}"`).join(' ');

    return `
        <button
            type="${type}"
            ${id ? `id="${id}"` : ''}
            ${disabled ? 'disabled' : ''}
            ${dataAttrs}
            class="${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}"
        >
            ${contentHtml}
        </button>
    `;
}

// ==================== Loading States ====================

/**
 * Render a skeleton loading placeholder
 * @param {string} type - 'card' | 'text' | 'circle' | 'article'
 * @param {number} count - Number of skeleton items to render
 */
function renderSkeleton(type = 'card', count = 1) {
    const skeletons = [];

    for (let i = 0; i < count; i++) {
        let html = '';
        switch (type) {
            case 'card':
                html = `
                    <div class="flex items-start gap-4 p-4 border-b border-outline-variant/30">
                        <div class="skeleton flex-shrink-0 w-10 h-10 rounded-full"></div>
                        <div class="flex-1 space-y-2">
                            <div class="skeleton h-4 rounded w-3/4"></div>
                            <div class="skeleton h-3 rounded w-full"></div>
                            <div class="skeleton h-3 rounded w-1/2"></div>
                        </div>
                    </div>
                `;
                break;
            case 'text':
                html = `<div class="skeleton h-4 rounded w-full mb-2"></div>`;
                break;
            case 'circle':
                html = `<div class="skeleton w-12 h-12 rounded-full"></div>`;
                break;
            case 'article':
                html = `
                    <div class="px-6 py-6 space-y-4">
                        <div class="skeleton h-4 rounded w-1/3"></div>
                        <div class="skeleton h-8 rounded w-full"></div>
                        <div class="skeleton h-32 rounded-xl w-full"></div>
                        <div class="space-y-2">
                            <div class="skeleton h-3 rounded w-full"></div>
                            <div class="skeleton h-3 rounded w-full"></div>
                            <div class="skeleton h-3 rounded w-2/3"></div>
                        </div>
                    </div>
                `;
                break;
        }
        skeletons.push(html);
    }

    return skeletons.join('');
}

/**
 * Render a spinner loading indicator
 * @param {string} size - 'sm' | 'md' | 'lg'
 * @param {string} color - Tailwind color class
 */
function renderSpinner(size = 'md', color = 'text-primary') {
    const sizeClasses = {
        sm: 'w-4 h-4 border-2',
        md: 'w-6 h-6 border-2',
        lg: 'w-10 h-10 border-[3px]'
    };

    return `
        <div class="inline-block ${sizeClasses[size]} ${color} rounded-full border-t-transparent animate-spin" role="status">
            <span class="sr-only">加载中...</span>
        </div>
    `;
}

/**
 * Render a full-page loading state
 * @param {string} message - Loading message
 */
function renderFullPageLoading(message = '加载中...') {
    return `
        <div class="min-h-screen flex flex-col items-center justify-center gap-4 safe-top safe-bottom">
            ${renderSpinner('lg', 'text-golden-hour')}
            <p class="text-body-md text-on-surface-variant">${message}</p>
        </div>
    `;
}

// ==================== Empty States ====================

/**
 * Render an empty state illustration
 * @param {string} type - 'inbox' | 'favorites' | 'search' | 'error' | 'logs'
 * @param {string} title - Empty state title
 * @param {string} description - Empty state description
 * @param {string} actionText - Optional action button text
 * @param {string} actionIcon - Optional action button icon
 */
function renderEmptyState(type = 'inbox', title = '', description = '', actionText = '', actionIcon = '') {
    const presets = {
        inbox: { icon: 'inbox', title: '暂无资讯', description: '请检查数据源配置或手动刷新' },
        favorites: { icon: 'bookmark_border', title: '暂无收藏', description: '点击文章右侧的心形图标收藏' },
        search: { icon: 'search_off', title: '未找到结果', description: '尝试更换关键词或筛选条件' },
        error: { icon: 'error_outline', title: '出错了', description: '请稍后重试或检查网络连接' },
        logs: { icon: 'history', title: '暂无记录', description: '执行记录将在这里显示' },
        briefing: { icon: 'auto_awesome', title: '今日简报未生成', description: '点击重新生成按钮创建今日简报' }
    };

    const preset = presets[type] || presets.inbox;
    const finalTitle = title || preset.title;
    const finalDescription = description || preset.description;

    return `
        <div class="flex flex-col items-center justify-center py-16 px-6 empty-state-enter">
            <span class="material-symbols-outlined text-6xl text-outline-variant mb-4">${preset.icon}</span>
            <p class="text-body-md text-on-surface-variant text-center font-medium">${finalTitle}</p>
            <p class="text-body-sm text-on-surface-variant text-center mt-1">${finalDescription}</p>
            ${actionText ? `
                <div class="mt-6">
                    ${renderButton(actionText, { variant: 'outline', size: 'md', icon: actionIcon })}
                </div>
            ` : ''}
        </div>
    `;
}

// ==================== Modal & Toast ====================

/**
 * Render a modal dialog
 * @param {string} title - Modal title
 * @param {string} content - Modal content HTML
 * @param {Array} actions - Array of action buttons [{ text, variant, onClick }]
 */
function renderModal(title, content, actions = []) {
    const actionsHtml = actions.map((action, i) =>
        renderButton(action.text, {
            variant: action.variant || 'primary',
            size: 'md',
            className: action.className || '',
            dataset: { action: i }
        })
    ).join('');

    return `
        <div class="modal-overlay fixed inset-0 bg-black/40 z-50 flex items-end justify-center animate-fade-in" role="dialog" aria-modal="true">
            <div class="modal-content bg-surface w-full max-w-readable rounded-t-2xl p-6 animate-slide-up">
                <div class="flex items-center justify-between mb-6">
                    <h3 class="text-headline-sm font-sans-body font-semibold">${title}</h3>
                    <button class="modal-close-btn material-symbols-outlined text-on-surface-variant p-1 rounded-full hover:bg-surface-container transition-colors">close</button>
                </div>
                <div class="modal-body">${content}</div>
                ${actionsHtml ? `<div class="flex gap-3 mt-6">${actionsHtml}</div>` : ''}
            </div>
        </div>
    `;
}

/**
 * Show a confirmation dialog
 * @param {string} title - Dialog title
 * @param {string} message - Dialog message
 * @param {Function} onConfirm - Callback when confirmed
 * @param {Function} onCancel - Callback when cancelled
 */
function showConfirmDialog(title, message, onConfirm, onCancel) {
    const modal = document.createElement('div');
    modal.innerHTML = renderModal(title, `
        <p class="text-body-md text-on-surface-variant">${message}</p>
    `, [
        { text: '取消', variant: 'ghost', className: 'flex-1' },
        { text: '确认', variant: 'primary', className: 'flex-1' }
    ]);

    document.body.appendChild(modal);

    const overlay = modal.querySelector('.modal-overlay');
    const closeBtn = modal.querySelector('.modal-close-btn');
    const actionBtns = modal.querySelectorAll('[data-action]');

    const close = () => {
        overlay.classList.add('animate-fade-out');
        setTimeout(() => modal.remove(), 200);
    };

    closeBtn?.addEventListener('click', () => {
        close();
        onCancel?.();
    });

    overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
            close();
            onCancel?.();
        }
    });

    actionBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const actionIndex = parseInt(btn.dataset.action);
            close();
            if (actionIndex === 1) {
                onConfirm?.();
            } else {
                onCancel?.();
            }
        });
    });
}

// ==================== Form Components ====================

/**
 * Render a form input field
 * @param {string} label - Input label
 * @param {Object} options - Input options
 */
function renderInput(label, options = {}) {
    const {
        type = 'text',
        id = '',
        placeholder = '',
        value = '',
        className = '',
        icon = ''
    } = options;

    const iconHtml = icon ? `<span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant">${icon}</span>` : '';
    const paddingClass = icon ? 'pl-12' : 'pl-4';

    return `
        <div class="form-field ${className}">
            ${label ? `<label class="text-label-md font-semibold text-on-surface mb-2 block">${label}</label>` : ''}
            <div class="relative">
                ${iconHtml}
                <input
                    type="${type}"
                    ${id ? `id="${id}"` : ''}
                    placeholder="${placeholder}"
                    value="${value}"
                    class="w-full py-3 ${paddingClass} pr-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                >
            </div>
        </div>
    `;
}

/**
 * Render a select dropdown
 * @param {string} label - Select label
 * @param {Array} options - Array of { value, label, selected }
 * @param {Object} config - Additional config
 */
function renderSelect(label, options = [], config = {}) {
    const { id = '', className = '' } = config;

    const optionsHtml = options.map(opt =>
        `<option value="${opt.value}" ${opt.selected ? 'selected' : ''}>${opt.label}</option>`
    ).join('');

    return `
        <div class="form-field ${className}">
            ${label ? `<label class="text-label-md font-semibold text-on-surface mb-2 block">${label}</label>` : ''}
            <select
                ${id ? `id="${id}"` : ''}
                class="w-full py-3 px-4 rounded-xl bg-surface-container-low border border-outline-variant text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors appearance-none"
            >
                ${optionsHtml}
            </select>
        </div>
    `;
}

// ==================== Data Display ====================

/**
 * Render a stat card
 * @param {string} value - Stat value
 * @param {string} label - Stat label
 * @param {string} trend - Optional trend indicator ('up' | 'down' | 'neutral')
 * @param {string} trendValue - Optional trend value text
 */
function renderStatCard(value, label, trend = '', trendValue = '') {
    const trendIcons = {
        up: 'trending_up',
        down: 'trending_down',
        neutral: 'trending_flat'
    };
    const trendColors = {
        up: 'text-green-600',
        down: 'text-error',
        neutral: 'text-on-surface-variant'
    };

    const trendHtml = trend ? `
        <div class="flex items-center gap-1 mt-1 ${trendColors[trend]}">
            <span class="material-symbols-outlined text-sm">${trendIcons[trend]}</span>
            <span class="text-label-sm">${trendValue}</span>
        </div>
    ` : '';

    return `
        <div class="text-center p-4 rounded-xl bg-surface-container-low">
            <div class="text-headline-sm font-bold text-on-surface">${value}</div>
            <div class="text-label-sm text-on-surface-variant mt-1">${label}</div>
            ${trendHtml}
        </div>
    `;
}

/**
 * Render a progress step indicator
 * @param {number} current - Current step (1-based)
 * @param {number} total - Total steps
 * @param {Array} labels - Step labels
 */
function renderStepIndicator(current, total, labels = []) {
    const steps = [];
    for (let i = 1; i <= total; i++) {
        const isActive = i === current;
        const isCompleted = i < current;
        const stepClass = isActive
            ? 'bg-primary text-on-primary'
            : isCompleted
                ? 'bg-primary-container text-on-primary-container'
                : 'bg-surface-container-high text-on-surface-variant';

        steps.push(`
            <div class="flex items-center ${i < total ? 'flex-1' : ''}">
                <div class="flex flex-col items-center">
                    <div class="w-8 h-8 rounded-full ${stepClass} flex items-center justify-center text-label-sm font-semibold transition-colors">
                        ${isCompleted ? '<span class="material-symbols-outlined text-base">check</span>' : i}
                    </div>
                    ${labels[i - 1] ? `<span class="text-label-sm mt-1 ${isActive ? 'text-on-surface font-medium' : 'text-on-surface-variant'}">${labels[i - 1]}</span>` : ''}
                </div>
                ${i < total ? `<div class="flex-1 h-px mx-2 ${isCompleted ? 'bg-primary' : 'bg-outline-variant'}"></div>` : ''}
            </div>
        `);
    }

    return `<div class="flex items-center px-4 py-4">${steps.join('')}</div>`;
}

// ==================== Animation Utilities ====================

/**
 * Add stagger animation to a list of elements
 * @param {string} selector - CSS selector for list items
 * @param {string} animationClass - Animation class to apply
 * @param {number} staggerDelay - Delay between items in ms
 */
function animateStagger(selector, animationClass = 'animate-fade-in-up', staggerDelay = 50) {
    const items = document.querySelectorAll(selector);
    items.forEach((item, i) => {
        item.style.animationDelay = `${i * staggerDelay}ms`;
        item.classList.add(animationClass);
    });
}

// ==================== CSS Animation Keyframes (injected) ====================

const componentStyles = `
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
    @keyframes fadeInUp {
        from { opacity: 0; transform: translateY(12px); }
        to { opacity: 1; transform: translateY(0); }
    }
    @keyframes slideUp {
        from { transform: translateY(100%); }
        to { transform: translateY(0); }
    }
    @keyframes slideDown {
        from { transform: translateY(0); opacity: 1; }
        to { transform: translateY(-8px); opacity: 0; }
    }
    @keyframes scaleIn {
        from { opacity: 0; transform: scale(0.95); }
        to { opacity: 1; transform: scale(1); }
    }
    @keyframes emptyStateEnter {
        from { opacity: 0; transform: scale(0.95); }
        to { opacity: 1; transform: scale(1); }
    }

    .animate-fade-in {
        animation: fadeIn 0.2s ease-out forwards;
    }
    .animate-fade-in-up {
        animation: fadeInUp 0.3s ease-out forwards;
        opacity: 0;
    }
    .animate-slide-up {
        animation: slideUp 0.3s ease-out forwards;
    }
    .animate-scale-in {
        animation: scaleIn 0.2s ease-out forwards;
    }
    .empty-state-enter {
        animation: emptyStateEnter 0.3s ease-out forwards;
    }
    .animate-fade-out {
        animation: fadeIn 0.2s ease-out reverse forwards;
    }

    /* Pull to refresh indicator */
    .ptr-indicator {
        transition: transform 0.2s ease-out;
    }
    .ptr-indicator.pulling {
        transform: translateY(0);
    }
    .ptr-indicator.refreshing {
        animation: ptrSpin 1s linear infinite;
    }
    @keyframes ptrSpin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }
`;

// Inject component styles
(function injectComponentStyles() {
    if (!document.getElementById('glean-component-styles')) {
        const style = document.createElement('style');
        style.id = 'glean-component-styles';
        style.textContent = componentStyles;
        document.head.appendChild(style);
    }
})();
