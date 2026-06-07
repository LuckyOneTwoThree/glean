import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';

/// 欢迎页
/// 对应设计图 _5：金色光晕背景 + flare图标 + 拾光 + 副标题 + 开始配置按钮
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade1;
  late Animation<double> _fade2;
  late Animation<double> _fade3;

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _goldenHour = Color(0xFFD4AF37);
  static const _onSurfaceVariant = Color(0xFF44474C);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _fade2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _fade3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景光晕
          _buildBackgroundGlow(),

          // 主内容
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // 图标 + 标题 + 副标题
                    FadeTransition(
                      opacity: _fade1,
                      child: _buildIcon(),
                    ),

                    const SizedBox(height: 24),

                    FadeTransition(
                      opacity: _fade2,
                      child: _buildTitle(),
                    ),

                    const SizedBox(height: 12),

                    FadeTransition(
                      opacity: _fade2,
                      child: _buildSubtitle(),
                    ),

                    const Spacer(flex: 2),

                    // 开始配置按钮
                    FadeTransition(
                      opacity: _fade3,
                      child: _buildStartButton(context),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 背景光晕：金色右上 + 墨水蓝左下
  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        // 金色光晕 - 右上
        Positioned(
          top: -MediaQuery.of(context).size.height * 0.1,
          right: -MediaQuery.of(context).size.width * 0.1,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE088).withOpacity(0.4),
            ),
          ),
        ),
        // 墨水蓝光晕 - 左下
        Positioned(
          bottom: -MediaQuery.of(context).size.height * 0.2,
          left: -MediaQuery.of(context).size.width * 0.1,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD2E4FB).withOpacity(0.5),
            ),
          ),
        ),
        // 模糊遮罩
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  /// 图标：白色卡片 + flare图标 + 阴影
  Widget _buildIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _inkBlue.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/logo.png',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 标题：拾光
  Widget _buildTitle() {
    return Text(
      '拾光',
      style: GoogleFonts.sourceSerif4(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: _inkBlue,
        height: 1.2,
        letterSpacing: -0.5,
      ),
    );
  }

  /// 副标题
  Widget _buildSubtitle() {
    return Text(
      '拾取有价值的光',
      style: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: _onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  /// 开始配置按钮：圆角胶囊 + 阴影 + 箭头hover动画
  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (_) => const OnboardingScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _inkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: _inkBlue.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '开始配置',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
