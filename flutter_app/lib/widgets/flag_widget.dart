import 'package:flutter/material.dart';

class FlagWidget extends StatelessWidget {
  final String code;

  const FlagWidget({
    super.key,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        'https://flagcdn.com/w80/${code.toLowerCase()}.png',
        width: 40,
        height: 28,
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
            width: 40,
            height: 28,
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
            width: 40,
            height: 28,
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