String formatHms(Duration d) {
  final totalSeconds = d.inSeconds;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;

  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(h)}:${two(m)}:${two(s)}';
}

String formatHm(Duration d) {
  final minutes = d.inMinutes;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m}m';
}
