# Flutter Race Timer 앱 개발 가이드
## VS Code Copilot & Claude 활용

---

## 📋 프로젝트 개요

### 목표
ESP32-C3 SuperMini와 USB Serial 통신으로 연결되는 레이스 타이머 앱 개발

### 타겟 플랫폼
- Android 태블릿 (Galaxy Tab S9)
- USB OTG 케이블 연결
- 실시간 타이머 표시

### 핵심 기능
1. USB Serial 통신 (115200 baud)
2. 대형 타이머 디스플레이 (전체화면)
3. START/STOP/RESET 버튼
4. ESP32 명령 송수신
5. 센서 감지 알림

---

## 🎯 개발 단계

```
Phase 1: 프로젝트 생성 및 기본 설정
Phase 2: USB Serial 통신 구현
Phase 3: UI 디자인 및 타이머 로직
Phase 4: ESP32 통신 연동
Phase 5: 테스트 및 최적화
Phase 6: APK 빌드 및 배포
```

---

## 📱 Phase 1: 프로젝트 생성 및 기본 설정

### 작업 내용
- Flutter 프로젝트 생성
- 필요한 패키지 추가
- Android 권한 설정

### Copilot 프롬프트

```
@workspace /new

Flutter 앱 프로젝트를 생성하고 싶습니다.

프로젝트 정보:
- 앱 이름: DeepcoRaceTimer
- 패키지명: com.ezmaker.deepco_race_timer
- 설명: USB Serial 통신 기반 레이스 타이머 앱

필요한 기능:
1. USB Serial 통신 (usb_serial 패키지 사용)
2. 안드로이드 USB 호스트 모드 지원
3. Material Design 3 사용
4. 다크 테마

다음 단계를 안내해주세요:
1. 프로젝트 생성 명령어
2. pubspec.yaml 설정
3. Android 권한 설정 (AndroidManifest.xml)
4. 기본 프로젝트 구조
```

### 수동 작업

1. **프로젝트 생성**
   ```bash
   flutter create deepco_race_timer
   cd deepco_race_timer
   code .
   ```

2. **pubspec.yaml 수정**
   - Copilot이 제안한 내용 적용
   - 최소 패키지: `usb_serial`, `permission_handler`

3. **AndroidManifest.xml 수정**
   - USB 권한 추가
   - device_filter.xml 생성

### 검증
```bash
flutter pub get
flutter doctor
```

---

## 🔌 Phase 2: USB Serial 통신 구현

### 배경 정보

**ESP32 통신 프로토콜:**

| 방향 | 명령/응답 | 설명 |
|------|----------|------|
| 앱→ESP32 | `START\n` | 타이머 시작 |
| 앱→ESP32 | `STOP\n` | 타이머 정지 |
| 앱→ESP32 | `RESET\n` | 타이머 리셋 |
| ESP32→앱 | `READY` | 초기화 완료 |
| ESP32→앱 | `STARTED` | 시작 확인 |
| ESP32→앱 | `STOPPED` | 정지 확인 |
| ESP32→앱 | `RESET` | 리셋 확인 |
| ESP32→앱 | `DETECTED` | 센서 감지 |

**USB 설정:**
- Baud Rate: 115200 (형식적, USB CDC는 무시)
- Data Bits: 8
- Stop Bits: 1
- Parity: None

### Copilot 프롬프트

```
@workspace

USB Serial 통신 모듈을 구현해주세요.

요구사항:

1. USB 장치 연결/해제 관리
   - 자동 장치 검색
   - 연결 상태 모니터링
   - 재연결 로직

2. 통신 설정
   - Baud rate: 115200
   - Data bits: 8, Stop bits: 1, Parity: None
   
3. 송신 함수
   - sendCommand(String command): ESP32에 명령 전송
   - 명령: "START", "STOP", "RESET"

4. 수신 함수
   - StreamController로 실시간 데이터 수신
   - 응답: "READY", "STARTED", "STOPPED", "RESET", "DETECTED"

5. 에러 처리
   - 장치 연결 실패
   - 통신 타임아웃
   - 권한 거부

구조:
```dart
class UsbSerialService {
  Stream<String> get dataStream;
  Future<bool> connect();
  Future<void> disconnect();
  Future<void> sendCommand(String cmd);
}
```

lib/services/usb_serial_service.dart 파일로 작성해주세요.
```

### 검증
- USB 장치 연결 테스트
- 명령 송신 확인
- 응답 수신 확인

---

## 🎨 Phase 3: UI 디자인 및 타이머 로직

### 화면 레이아웃 (가로형 고정)

```
┌─────────────────────────────────┐
│      🏁 RACE TIMER 🏁          │
├─────────────────────────────────┤
│                                 │
│         00:00:00                │  ← 초대형 폰트 (150sp)
│                                 │
├─────────────────────────────────┤
│      ⚪ 대기 중                 │  ← 상태 표시
├─────────────────────────────────┤
│                                 │
│  [START]  [STOP]  [RESET]      │  ← 큰 버튼
│                                 │
├─────────────────────────────────┤
│  USB: ✅ 연결됨                 │  ← 연결 상태
└─────────────────────────────────┘
```

### Copilot 프롬프트

```
@workspace

Race Timer 메인 화면 UI를 구현해주세요.

레이아웃 요구사항:

1. 타이머 디스플레이
   - 폰트 크기: 96-120
   - 포맷: MM:SS:ms
   - 중앙 정렬
   - 색상: 녹색 (실행 중), 회색 (대기)

2. 상태 표시
   - "대기 중" / "주행 중..." / "정지됨"
   - 이모지 사용: ⚪ 🟢 🔴

3. 제어 버튼 (3개)
   - START: 녹색 배경
   - STOP: 빨간색 배경
   - RESET: 주황색 배경
   - 크기: 최소 80x80
   - 터치 피드백 효과

4. 연결 상태 (하단)
   - USB 연결: ✅ / ❌
   - 작은 폰트, 반투명

5. 전체화면 모드
   - 상단 바 숨김
   - 가로/세로 모드 모두 지원

다음 파일 구조로 작성:
- lib/screens/timer_screen.dart (메인 화면)
- lib/widgets/timer_display.dart (타이머 위젯)
- lib/widgets/control_buttons.dart (버튼 위젯)
```

### Copilot 프롬프트 (타이머 로직)

```
@workspace

타이머 로직을 구현해주세요.

요구사항:

1. 타이머 상태 관리 (Provider 또는 Riverpod)
   - State: READY, RUNNING, STOPPED
   - 경과 시간 추적 (밀리초 단위)

2. 기능
   - start(): 타이머 시작
   - stop(): 타이머 정지 (시간 유지)
   - reset(): 타이머 리셋 (00:00:00)
   - getFormattedTime(): "HH:MM:SS" 반환

3. 업데이트 주기
   - 100ms마다 화면 갱신
   - Timer.periodic 사용

4. ESP32 연동
   - start() 호출 시 → sendCommand("START")
   - stop() 호출 시 → sendCommand("STOP")
   - reset() 호출 시 → sendCommand("RESET")
   - "DETECTED" 수신 시 → 자동 stop()

구조:
```dart
class TimerController extends ChangeNotifier {
  TimerState state;
  Duration elapsed;
  
  void start();
  void stop();
  void reset();
  String getFormattedTime();
}
```

lib/controllers/timer_controller.dart로 작성해주세요.
```

### 검증
- 화면 레이아웃 확인
- 버튼 동작 확인
- 타이머 카운트 확인

---

## 🔗 Phase 4: ESP32 통신 연동

### Copilot 프롬프트

```
@workspace

메인 화면과 USB Serial 통신을 통합해주세요.

통합 요구사항:

1. 초기화 시퀀스
   - 앱 시작 → USB 장치 검색
   - 자동 연결 시도
   - "READY" 대기

2. 버튼 동작
   - START 버튼 클릭 → ESP32에 "START" 전송 → "STARTED" 응답 대기 → 타이머 시작
   - STOP 버튼 클릭 → ESP32에 "STOP" 전송 → "STOPPED" 응답 대기 → 타이머 정지
   - RESET 버튼 클릭 → ESP32에 "RESET" 전송 → "RESET" 응답 대기 → 타이머 리셋

3. ESP32 이벤트 처리
   - "DETECTED" 수신 → 자동으로 타이머 정지
   - 화면 깜빡임 효과 (선택사항)
   - 진동 피드백 (선택사항)

4. 에러 처리
   - USB 연결 끊김 → 재연결 시도
   - 응답 타임아웃 (3초) → 에러 표시
   - 명령 재시도 로직

5. 디버그 로그
   - 모든 송수신 데이터 로깅
   - 연결 상태 변경 로깅

main.dart를 완성하고, 각 모듈을 연결해주세요.
```

### 검증
- START → ESP32 반응 확인
- STOP → ESP32 반응 확인
- RESET → ESP32 반응 확인
- 센서 감지 → 자동 정지 확인

---

## 🧪 Phase 5: 테스트 및 최적화

### Copilot 프롬프트

```
@workspace

앱의 안정성과 사용성을 개선해주세요.

개선 사항:

1. 에러 처리 강화
   - USB 연결 끊김 복구
   - 명령 전송 실패 재시도
   - 사용자 친화적 에러 메시지

2. 사용성 개선
   - 로딩 인디케이터
   - 터치 피드백 강화
   - 화면 꺼짐 방지 (wakelock)

3. 성능 최적화
   - 불필요한 리빌드 최소화
   - 메모리 누수 방지
   - 백그라운드 처리

4. 추가 기능 (선택)
   - 랩타임 기록
   - 최고 기록 표시
   - 결과 저장/공유

5. 디자인 개선
   - 애니메이션 효과
   - 색상 테마 조정
   - 폰트 최적화

각 개선 사항을 단계별로 제안해주세요.
```

### 테스트 체크리스트

```
✅ USB 연결 테스트
✅ 명령 송수신 테스트
✅ 타이머 정확도 테스트
✅ 버튼 응답 속도 테스트
✅ 장기 실행 안정성 테스트
✅ 에러 복구 테스트
✅ 배터리 소모 테스트
```

---

## 📦 Phase 6: APK 빌드 및 배포

### Copilot 프롬프트

```
@workspace

프로덕션 APK를 빌드하고 싶습니다.

필요한 작업:

1. 앱 아이콘 설정
   - android/app/src/main/res/mipmap-* 폴더
   - 여러 해상도 준비

2. 앱 이름 및 버전 설정
   - android/app/build.gradle
   - applicationId, versionCode, versionName

3. 서명 설정 (선택사항)
   - Keystore 생성 방법
   - key.properties 설정

4. 빌드 최적화
   - ProGuard 설정
   - 불필요한 리소스 제거
   - APK 크기 최소화

5. 빌드 명령어
   - Release APK 생성
   - APK 위치 확인

단계별로 안내해주세요.
```

### 수동 작업

1. **Release APK 빌드**
   ```bash
   flutter build apk --release
   ```

2. **APK 위치**
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. **태블릿 설치**
   - USB로 APK 전송
   - 또는 클라우드 저장소 사용

---

## 🎯 전체 프로젝트 구조

```
deepco_race_timer/
├── lib/
│   ├── main.dart                      # 앱 진입점
│   ├── screens/
│   │   └── timer_screen.dart         # 메인 타이머 화면
│   ├── widgets/
│   │   ├── timer_display.dart        # 타이머 디스플레이
│   │   ├── control_buttons.dart      # 제어 버튼
│   │   └── connection_status.dart    # 연결 상태
│   ├── services/
│   │   └── usb_serial_service.dart   # USB Serial 통신
│   ├── controllers/
│   │   └── timer_controller.dart     # 타이머 로직
│   └── models/
│       └── timer_state.dart          # 상태 모델
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               └── res/
│                   └── xml/
│                       └── device_filter.xml
└── pubspec.yaml
```

---

## 💡 Copilot 활용 팁

### 효과적인 프롬프트 작성

1. **컨텍스트 제공**
   ```
   @workspace 사용 (전체 프로젝트 컨텍스트)
   파일 경로 명시
   ```

2. **명확한 요구사항**
   ```
   입력/출력 명시
   예제 코드 제공
   예상 동작 설명
   ```

3. **단계별 진행**
   ```
   한 번에 하나의 기능만
   검증 후 다음 단계
   ```

### Chat 활용 방법

1. **Copilot Chat 열기**
   ```
   Ctrl+Shift+I (또는 Cmd+Shift+I)
   ```

2. **에이전트 선택**
   ```
   @workspace - 전체 프로젝트
   @terminal - 명령어 도움
   Claude 선택 (가능한 경우)
   ```

3. **인라인 코드 생성**
   ```
   Ctrl+I (코드 에디터 내에서)
   ```

---

## 🔧 트러블슈팅 프롬프트

### USB 연결 문제

```
@workspace

USB Serial 연결이 안 됩니다.

증상:
[여기에 에러 메시지 붙여넣기]

확인 사항:
- 태블릿 USB 디버깅: ON
- USB OTG 케이블 사용
- ESP32 정상 부팅 확인

어떻게 디버깅해야 하나요?
```

### 타이머 정확도 문제

```
@workspace

타이머가 실제 시간과 차이가 납니다.

현상:
- 1분 후 실제 시간과 2-3초 차이
- 시간이 지날수록 차이 증가

현재 구현:
[timer_controller.dart 코드 붙여넣기]

어떻게 개선할 수 있나요?
```

### 성능 최적화

```
@workspace

앱이 느리고 버벅입니다.

증상:
- 버튼 클릭 반응 느림
- 화면 전환 끊김
- 메모리 사용량 증가

프로파일링 결과:
[Flutter DevTools 스크린샷 또는 데이터]

최적화 방법을 제안해주세요.
```

---

## 📚 참고 자료

### Flutter 공식 문서
- https://docs.flutter.dev/
- https://pub.dev/packages/usb_serial

### USB Serial 예제
- https://github.com/altera2015/usbserial

### ESP32 통신
- MicroPython Serial: https://docs.micropython.org/

---

## ✅ 개발 완료 체크리스트

```
Phase 1: 프로젝트 생성
  ✅ Flutter 프로젝트 생성
  ✅ 패키지 설치
  ✅ Android 권한 설정
  ✅ 기본 구조 확인

Phase 2: USB Serial 통신
  ✅ USB 장치 검색
  ✅ 연결/해제 구현
  ✅ 명령 송신 구현
  ✅ 응답 수신 구현
  ✅ 에러 처리

Phase 3: UI & 타이머
  ✅ 화면 레이아웃
  ✅ 타이머 디스플레이
  ✅ 제어 버튼
  ✅ 타이머 로직
  ✅ 상태 관리

Phase 4: 통합
  ✅ ESP32 연동
  ✅ 명령 응답 처리
  ✅ 센서 이벤트 처리
  ✅ 에러 처리

Phase 5: 테스트
  ✅ 기능 테스트
  ✅ 성능 테스트
  ✅ 안정성 테스트
  ✅ 사용성 개선

Phase 6: 빌드
  ✅ APK 빌드
  ✅ 설치 테스트
  ✅ 최종 검증
```

---

## 🚀 시작하기

1. **이 파일을 프로젝트 루트에 저장**
   ```
   deepco_race_timer/DEV_GUIDE.md
   ```

2. **VS Code Copilot Chat 열기**
   ```
   Ctrl+Shift+I (또는 Cmd+Shift+I)
   ```

3. **Phase 1 프롬프트 복사**
   - 위의 "Phase 1" 섹션의 프롬프트 복사
   - Copilot Chat에 붙여넣기
   - Enter

4. **단계별 진행**
   - 각 Phase를 순서대로 진행
   - 검증 후 다음 단계
   - 문제 발생 시 트러블슈팅 프롬프트 활용

---

## 💬 Copilot과 대화하는 법

### 좋은 예시 ✅

```
@workspace

lib/services/usb_serial_service.dart 파일의 connect() 함수가
타임아웃 에러를 발생시킵니다.

에러 메시지:
TimeoutException after 5 seconds

현재 코드:
[코드 붙여넣기]

어떻게 수정해야 하나요?
```

### 나쁜 예시 ❌

```
안돼요
```

---

**개발 시작을 축하합니다! 🎉**

문제가 생기면 언제든지 Copilot에게 물어보세요!
