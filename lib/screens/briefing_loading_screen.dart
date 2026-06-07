import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';

/// 简报生成加载页面
/// 首次进入App时强制触发真实RSS采集，采集成功后才显示完成按钮
class BriefingLoadingScreen extends ConsumerStatefulWidget {
  final Widget nextScreen;
  final bool showCompletionButton;

  const BriefingLoadingScreen({
    super.key,
    required this.nextScreen,
    this.showCompletionButton = false,
  });

  @override
  ConsumerState<BriefingLoadingScreen> createState() => _BriefingLoadingScreenState();
}

class _BriefingLoadingScreenState extends ConsumerState<BriefingLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  bool _isCompleted = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _headline = '正在为你拾取\n今日之光';

  final List<_LoadingStep> _steps = [
    _LoadingStep(
      icon: Icons.language,
      title: '扫描全网信息源',
      subtitle: '正在拉取高质量信源...',
    ),
    _LoadingStep(
      icon: Icons.psychology,
      title: '提炼核心洞察',
      subtitle: 'AI 深度分析降噪中...',
    ),
    _LoadingStep(
      icon: Icons.auto_awesome,
      title: '排版专属简报',
      subtitle: '应用清晰格式与排版',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _startRealFetch();
  }

  void _startRealFetch() {
    // Step 1 动画：立即开始
    if (mounted) setState(() => _currentStep = 0);
    _progressController.animateTo(0.3, duration: const Duration(seconds: 2));

    // 触发真实的简报生成
    ref.read(briefingServiceProvider).generate('auto').then((_) {
      if (!mounted) return;

      // 采集成功，刷新所有数据
      refreshData(ref);

      // Step 2 动画
      setState(() => _currentStep = 1);
      _progressController.animateTo(0.7, duration: const Duration(milliseconds: 800));

      // Step 3 + 完成
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() => _currentStep = 2);
        _progressController.animateTo(1.0, duration: const Duration(milliseconds: 500));

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _isCompleted = true;
            _headline = '今日简报已就绪';
          });
        });
      });
    }).catchError((error) {
      if (!mounted) return;

      refreshData(ref);

      setState(() {
        _hasError = true;
        _headline = '采集遇到问题';
        _errorMessage = '部分信源可能无法访问，你可以稍后重试或直接进入查看已有内容';
      });
      _progressController.animateTo(1.0, duration: const Duration(milliseconds: 500));
    });
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isCompleted = false;
      _errorMessage = '';
      _currentStep = 0;
      _headline = '正在为你拾取\n今日之光';
    });
    _progressController.reset();
    _startRealFetch();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onComplete() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 标题
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    _headline,
                    key: ValueKey(_headline),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: const Color(0xFF1A2B3C),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 副标题
                AnimatedOpacity(
                  opacity: (_isCompleted || _hasError) ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    '请稍候，AI正在构建您的专属知识晶体',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: const Color(0xFF74777D),
                    ),
                  ),
                ),

                // 错误信息
                if (_hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: const Color(0xFF74777D),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // 进度卡片
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC4C6CD).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A2B3C).withOpacity(0.04),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProgressLine(),
                      const SizedBox(height: 24),
                      ...List.generate(_steps.length, (index) {
                        return _buildStepItem(index);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // 完成按钮 / 错误按钮
                AnimatedOpacity(
                  opacity: (_isCompleted || _hasError) ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSlide(
                    offset: (_isCompleted || _hasError) ? Offset.zero : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 800),
                    child: _buildActionButton(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_hasError) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                '重试',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A2B3C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _onComplete,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                '先看看',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_isCompleted) {
      return FilledButton.icon(
        onPressed: _onComplete,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(
          widget.showCompletionButton ? '开启我的拾光之旅' : '查看简报',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1A2B3C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProgressLine() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEED),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hasError
                      ? [const Color(0xFFBA1A1A), const Color(0xFFE57373)]
                      : [const Color(0xFF1A2B3C), const Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem(int index) {
    final step = _steps[index];
    final isActive = index == _currentStep && !_isCompleted && !_hasError;
    final isCompleted = index < _currentStep || _isCompleted;
    final isPending = index > _currentStep && !_isCompleted && !_hasError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF1A2B3C)
                  : isActive
                      ? const Color(0xFFD4AF37).withOpacity(0.1)
                      : const Color(0xFFF3F4F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF1A2B3C)
                    : isCompleted
                        ? const Color(0xFF1A2B3C)
                        : const Color(0xFFC4C6CD).withOpacity(0.3),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1A2B3C).withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Icon(
                          step.icon,
                          size: 20,
                          color: isActive
                              ? Color.lerp(
                                  const Color(0xFF1A2B3C),
                                  const Color(0xFFD4AF37),
                                  _pulseController.value,
                                )
                              : const Color(0xFF74777D),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1A2B3C)
                        : isCompleted
                            ? const Color(0xFF1A2B3C)
                            : const Color(0xFF74777D),
                  ),
                  child: Text(step.title),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: isActive
                        ? const Color(0xFF44474C)
                        : isCompleted
                            ? const Color(0xFF74777D)
                            : const Color(0xFF74777D).withOpacity(0.5),
                  ),
                  child: Text(step.subtitle),
                ),
              ],
            ),
          ),
          if (isCompleted && !_isCompleted)
            const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
        ],
      ),
    );
  }
}

class _LoadingStep {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LoadingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
