class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.error});

  final String message;
  final int? statusCode;
  final Object? error;

  @override
  String toString() => message;
}
