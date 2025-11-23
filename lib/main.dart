import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 방향 고정 (가로 모드만)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 전체화면 모드 (상태바/네비게이션바 숨김)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 화면 꺼짐 방지
  WakelockPlus.enable();

  runApp(const DeepcoRaceTimerApp());
}

class DeepcoRaceTimerApp extends StatelessWidget {
  const DeepcoRaceTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepcoRaceTimer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TimerScreen(),
    );
  }
}
