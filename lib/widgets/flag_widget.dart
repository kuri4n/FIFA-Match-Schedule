import 'package:flutter/material.dart';

class FlagWidget extends StatelessWidget {
  final String code;
  final double width;
  final double height;
  final double borderRadius;

  const FlagWidget({
    super.key,
    required this.code,
    this.width = 40,
    this.height = 28,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final safeCode = code.trim().toLowerCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        'https://flagcdn.com/w80/$safeCode.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Icon(
              Icons.flag,
              size: 16,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}