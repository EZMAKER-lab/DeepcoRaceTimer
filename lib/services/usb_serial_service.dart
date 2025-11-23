import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

/// ESP32-C3와 USB Serial 통신을 담당하는 서비스 클래스
class UsbSerialService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  /// 데이터 수신 스트림
  Stream<String> get dataStream => _dataController.stream;

  /// 연결 상태 스트림
  Stream<bool> get connectionStream => _connectionController.stream;

  /// 현재 연결 상태
  bool get isConnected => _isConnected;

  /// USB 장치 검색 및 연결
  Future<bool> connect() async {
    try {
      debugPrint('[USB] 장치 검색 중...');

      // USB 장치 목록 가져오기
      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        debugPrint('[USB] 연결된 USB 장치가 없습니다.');
        _updateConnectionStatus(false);
        return false;
      }

      debugPrint('[USB] 발견된 장치: ${devices.length}개');

      // 첫 번째 장치 선택 (ESP32-C3)
      UsbDevice device = devices.first;
      debugPrint('[USB] 장치 정보: VID=${device.vid}, PID=${device.pid}');

      // 포트 열기
      _port = await device.create();

      if (_port == null) {
        debugPrint('[USB] 포트 생성 실패');
        _updateConnectionStatus(false);
        return false;
      }

      // 포트 설정
      bool openResult = await _port!.open();
      if (!openResult) {
        debugPrint('[USB] 포트 열기 실패');
        _updateConnectionStatus(false);
        return false;
      }

      // Serial 설정 (115200 baud - USB CDC는 실제로 무시하지만 형식상 설정)
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      debugPrint('[USB] 포트 설정 완료 (115200 baud)');

      // 데이터 수신 시작
      _startListening();

      _updateConnectionStatus(true);
      debugPrint('[USB] 연결 성공!');

      return true;
    } catch (e) {
      debugPrint('[USB] 연결 오류: $e');
      _updateConnectionStatus(false);
      return false;
    }
  }

  /// 데이터 수신 리스너 시작
  void _startListening() {
    if (_port == null) return;

    _subscription = _port!.inputStream?.listen(
      (Uint8List data) {
        // 바이트 데이터를 문자열로 변환
        String received = String.fromCharCodes(data).trim();

        if (received.isNotEmpty) {
          debugPrint('[USB] ← 수신: $received');
          _dataController.add(received);
        }
      },
      onError: (error) {
        debugPrint('[USB] 수신 오류: $error');
        _handleDisconnection();
      },
      onDone: () {
        debugPrint('[USB] 수신 스트림 종료');
        _handleDisconnection();
      },
    );
  }

  /// ESP32에 명령 전송
  Future<void> sendCommand(String command) async {
    if (_port == null || !_isConnected) {
      debugPrint('[USB] 연결되지 않음 - 명령 전송 실패');
      throw Exception('USB가 연결되지 않았습니다');
    }

    try {
      // 명령에 줄바꿈 추가
      String cmd = command.trim() + '\n';

      // 문자열을 바이트로 변환하여 전송
      await _port!.write(Uint8List.fromList(cmd.codeUnits));

      debugPrint('[USB] → 송신: $command');
    } catch (e) {
      debugPrint('[USB] 송신 오류: $e');
      throw Exception('명령 전송 실패: $e');
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    try {
      debugPrint('[USB] 연결 해제 중...');

      // 수신 리스너 중지
      await _subscription?.cancel();
      _subscription = null;

      // 포트 닫기
      await _port?.close();
      _port = null;

      _updateConnectionStatus(false);
      debugPrint('[USB] 연결 해제 완료');
    } catch (e) {
      debugPrint('[USB] 연결 해제 오류: $e');
    }
  }

  /// 연결 끊김 처리
  void _handleDisconnection() {
    _updateConnectionStatus(false);
    _port = null;
    _subscription?.cancel();
    _subscription = null;
  }

  /// 연결 상태 업데이트
  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);
  }

  /// 재연결 시도
  Future<bool> reconnect() async {
    debugPrint('[USB] 재연결 시도...');
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    return await connect();
  }

  /// 리소스 정리
  void dispose() {
    _subscription?.cancel();
    _dataController.close();
    _connectionController.close();
    _port?.close();
  }
}
