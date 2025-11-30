import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String status;
  final bool isProcessing;
  final Animation<double> fadeAnimation;

  const StatusCard({
    super.key,
    required this.status,
    required this.isProcessing,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - fadeAnimation.value)),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    if (isProcessing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
        ),
      );
    } else if (status.contains('✅')) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withOpacity(0.1),
        ),
        child: const Icon(Icons.check, color: Colors.green, size: 16),
      );
    } else if (status.contains('❌')) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 24);
    } else {
      return const Icon(Icons.info_outline, color: Color(0xFF667eea), size: 24);
    }
  }
}
