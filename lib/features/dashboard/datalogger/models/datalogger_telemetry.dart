class DataloggerTelemetry {
  final DateTime? timestamp;
  final List<double?> temps;

  DataloggerTelemetry({
    required this.timestamp,
    required this.temps,
  });
}