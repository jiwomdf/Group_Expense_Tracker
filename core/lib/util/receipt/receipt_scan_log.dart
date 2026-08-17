/// Records what each stage of the scan did, so a wrong total can be traced back
/// to the step that lost it instead of being guessed at.
///
/// Entries are timestamped from the moment the log is created, which also makes
/// it obvious which stage is slow.
class ReceiptScanLog {
  final List<String> _entries = [];
  final Stopwatch _elapsed = Stopwatch()..start();

  /// Adds a stage line, e.g. `stage('OCR', '42 lines in 8 blocks')`.
  void stage(String name, String detail) {
    _entries.add(
        '[${_elapsed.elapsedMilliseconds.toString().padLeft(4)}ms] $name: $detail');
  }

  /// Adds a detail line under the stage above it.
  void detail(String detail) {
    _entries.add('${' ' * 9}   $detail');
  }

  List<String> get entries => List.unmodifiable(_entries);
}
