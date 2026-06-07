import 'package:flutter/material.dart';

/// 确认对话框
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 实现组件
    return const SizedBox.shrink();
  }
}
