import 'package:flutter/material.dart';
import '../models/timer_state.dart';

/// 타이머 디스플레이 위젯
class TimerDisplay extends StatelessWidget {
  final String timeText;
  final TimerState state;

  const TimerDisplay({super.key, required this.timeText, required this.state});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // 화면 크기에 따라 동적으로 폰트 크기 조정
    // 태블릿 가로 모드를 고려하여 큰 폰트 사이즈 적용
    final fontSize = (screenWidth * 0.15).clamp(80.0, 200.0);

    // 상태에 따른 색상
    Color timeColor;
    switch (state) {
      case TimerState.running:
        timeColor = Colors.green;
        break;
      case TimerState.stopped:
        timeColor = Colors.red;
        break;
      case TimerState.ready:
        timeColor = Colors.grey;
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 타이머 텍스트 (화면 크기에 맞게 최대화)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: timeColor,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 8,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),

        // 상태 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getStateIcon(), size: fontSize * 0.25, color: timeColor),
            SizedBox(width: fontSize * 0.1),
            Text(
              _getStateText(),
              style: TextStyle(fontSize: fontSize * 0.2, color: timeColor),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStateIcon() {
    switch (state) {
      case TimerState.running:
        return Icons.play_circle_filled;
      case TimerState.stopped:
        return Icons.stop_circle;
      case TimerState.ready:
        return Icons.circle_outlined;
    }
  }

  String _getStateText() {
    switch (state) {
      case TimerState.running:
        return '주행 중...';
      case TimerState.stopped:
        return '정지됨';
      case TimerState.ready:
        return '대기 중';
    }
  }
}
