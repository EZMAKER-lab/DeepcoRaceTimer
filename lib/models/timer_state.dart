/// 타이머 상태
enum TimerState {
  /// 준비 상태 (00:00:00)
  ready,

  /// 실행 중
  running,

  /// 정지됨 (시간 유지)
  stopped,
}
