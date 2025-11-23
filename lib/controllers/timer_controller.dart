import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/timer_state.dart';
import '../services/usb_serial_service.dart';

/// 타이머 로직 및 ESP32 통신을 관리하는 컨트롤러
class TimerController extends ChangeNotifier {
  final UsbSerialService _usbService;

  TimerState _state = TimerState.ready;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  DateTime? _startTime;
  Duration _pausedDuration = Duration.zero;

  StreamSubscription? _dataSubscription;

  TimerController(this._usbService) {
    _listenToEsp32();
  }

  /// 현재 타이머 상태
  TimerState get state => _state;

  /// 경과 시간
  Duration get elapsed => _elapsed;

  /// 포맷된 시간 문자열 (MM:SS:ms)
  String getFormattedTime() {
    int totalMilliseconds = _elapsed.inMilliseconds;
    int minutes = (totalMilliseconds ~/ 60000);
    int seconds = ((totalMilliseconds % 60000) ~/ 1000);
    int centiseconds = ((totalMilliseconds % 1000) ~/ 10); // 100분의 1초 (10ms 단위)

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}:'
        '${centiseconds.toString().padLeft(2, '0')}';
  }

  /// ESP32 메시지 수신 리스너
  void _listenToEsp32() {
    _dataSubscription = _usbService.dataStream.listen((message) {
      debugPrint('[Timer] ESP32 메시지: $message');

      switch (message.trim().toUpperCase()) {
        case 'READY':
          debugPrint('[Timer] ESP32 준비 완료');
          break;

        case 'STARTED':
          debugPrint('[Timer] ESP32 시작 확인');
          break;

        case 'STOPPED':
          debugPrint('[Timer] ESP32 정지 확인');
          break;

        case 'RESET':
          debugPrint('[Timer] ESP32 리셋 확인');
          break;

        case 'DETECTED':
          debugPrint('[Timer] 센서 감지! - 자동 정지');
          _autoStop();
          break;
      }
    });
  }

  /// 타이머 시작
  Future<void> start() async {
    if (_state == TimerState.running) {
      debugPrint('[Timer] 이미 실행 중');
      return;
    }

    try {
      // ESP32에 START 명령 전송
      await _usbService.sendCommand('START');

      _state = TimerState.running;
      notifyListeners();

      // 1.5초 지연 후 타이머 시작 (차단기 올라가는 시간)
      await Future.delayed(const Duration(milliseconds: 1500));

      _startTime = DateTime.now().subtract(_pausedDuration);

      // 10ms마다 화면 업데이트 (100분의 1초 표시를 위해)
      _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (_startTime != null) {
          _elapsed = DateTime.now().difference(_startTime!);
          notifyListeners();
        }
      });

      debugPrint('[Timer] 1.5초 지연 후 시작');
    } catch (e) {
      debugPrint('[Timer] 시작 실패: $e');
      _state = TimerState.ready;
      notifyListeners();
    }
  }

  /// 타이머 정지
  Future<void> stop() async {
    if (_state != TimerState.running) {
      debugPrint('[Timer] 실행 중이 아님');
      return;
    }

    try {
      // ESP32에 STOP 명령 전송
      await _usbService.sendCommand('STOP');

      _timer?.cancel();
      _timer = null;
      _pausedDuration = _elapsed;
      _state = TimerState.stopped;

      notifyListeners();
      debugPrint('[Timer] 정지 - 시간: ${getFormattedTime()}');
    } catch (e) {
      debugPrint('[Timer] 정지 실패: $e');
    }
  }

  /// 센서 감지 시 자동 정지
  void _autoStop() async {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _timer = null;
    _pausedDuration = _elapsed;
    _state = TimerState.stopped;

    notifyListeners();
    debugPrint('[Timer] 자동 정지 - 시간: ${getFormattedTime()}');
  }

  /// 타이머 리셋
  Future<void> reset() async {
    try {
      // ESP32에 RESET 명령 전송
      await _usbService.sendCommand('RESET');

      _timer?.cancel();
      _timer = null;
      _elapsed = Duration.zero;
      _pausedDuration = Duration.zero;
      _startTime = null;
      _state = TimerState.ready;

      notifyListeners();
      debugPrint('[Timer] 리셋');
    } catch (e) {
      debugPrint('[Timer] 리셋 실패: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }
}
