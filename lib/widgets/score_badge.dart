import 'package:flutter/material.dart';

/// 评分徽章组件
class ScoreBadge extends StatelessWidget {
  final double score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, borderColor) = _getScoreStyle(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }

  (Color, Color, Color) _getScoreStyle(double score) {
    if (score >= 8.5) {
      return (
        const Color(0xFFD4AF37), // 金色文字
        const Color(0xFFD4AF37).withOpacity(0.1), // 金色背景
        const Color(0xFFD4AF37).withOpacity(0.2), // 金色边框
      );
    }
    if (score >= 7.0) {
      return (
        const Color(0xFF1A2B3C), // 深蓝文字
        const Color(0xFF1A2B3C).withOpacity(0.05), // 浅蓝背景
        const Color(0xFF1A2B3C).withOpacity(0.1), // 浅蓝边框
      );
    }
    if (score >= 5.0) {
      return (
        const Color(0xFF74777D), // 灰色文字
        const Color(0xFF74777D).withOpacity(0.05), // 浅灰背景
        const Color(0xFF74777D).withOpacity(0.1), // 浅灰边框
      );
    }
    return (
      const Color(0xFFBA1A1A), // 红色文字
      const Color(0xFFBA1A1A).withOpacity(0.05), // 浅红背景
      const Color(0xFFBA1A1A).withOpacity(0.1), // 浅红边框
    );
  }
}
