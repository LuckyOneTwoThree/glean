import 'package:flutter/material.dart';

/// 空状态组件
class EmptyState extends StatelessWidget {
  final String type;
  final String title;
  final String description;

  const EmptyState({
    super.key,
    required this.type,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 实现组件
    return const SizedBox.shrink();
  }
}
