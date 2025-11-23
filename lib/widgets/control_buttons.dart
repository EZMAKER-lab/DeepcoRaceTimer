import 'package:flutter/material.dart';

/// 제어 버튼 위젯
class ControlButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final bool isRunning;

  const ControlButtons({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // START 버튼
        _buildButton(
          label: 'START',
          icon: Icons.play_arrow,
          color: Colors.green,
          onPressed: isRunning ? null : onStart,
        ),

        // STOP 버튼
        _buildButton(
          label: 'STOP',
          icon: Icons.stop,
          color: Colors.red,
          onPressed: isRunning ? onStop : null,
        ),

        // RESET 버튼
        _buildButton(
          label: 'RESET',
          icon: Icons.refresh,
          color: Colors.orange,
          onPressed: onReset,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
