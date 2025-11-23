import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/timer_controller.dart';
import '../services/usb_serial_service.dart';
import '../widgets/timer_display.dart';
import '../widgets/control_buttons.dart';
import '../widgets/connection_status.dart';

/// 메인 타이머 화면
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late UsbSerialService _usbService;
  late TimerController _timerController;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _usbService = UsbSerialService();
    _timerController = TimerController(_usbService);

    // USB 연결 상태 리스너
    _usbService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // 앱 시작 시 USB 연결 시도
    _connectUsb();
  }

  Future<void> _connectUsb() async {
    bool success = await _usbService.connect();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('USB 장치를 찾을 수 없습니다. 연결을 확인해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reconnectUsb() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('재연결 중...'), duration: Duration(seconds: 1)),
    );

    bool success = await _usbService.reconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '연결 성공!' : '연결 실패'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _usbService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timerController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // 상단 영역: USB 연결 상태 + 재연결 버튼 (10%)
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 좌측: USB 연결 상태
                      ConnectionStatus(isConnected: _isConnected),
                      // 우측: 재연결 버튼
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _reconnectUsb,
                        tooltip: 'USB 재연결',
                      ),
                    ],
                  ),
                ),
              ),

              // 타이머 디스플레이 영역 (60%)
              Expanded(
                flex: 60,
                child: Center(
                  child: Consumer<TimerController>(
                    builder: (context, controller, child) {
                      return TimerDisplay(
                        timeText: controller.getFormattedTime(),
                        state: controller.state,
                      );
                    },
                  ),
                ),
              ),

              // 제어 버튼 영역 (30%)
              Expanded(
                flex: 30,
                child: Center(
                  child: Consumer<TimerController>(
                    builder: (context, controller, child) {
                      return ControlButtons(
                        onStart: controller.start,
                        onStop: controller.stop,
                        onReset: controller.reset,
                        isRunning: controller.state.name == 'running',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
