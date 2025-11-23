import 'package:flutter/material.dart';

/// USB 연결 상태 표시 위젯
class ConnectionStatus extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatus({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.usb : Icons.usb_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? '✅ USB 연결됨' : '❌ USB 연결 안됨',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
