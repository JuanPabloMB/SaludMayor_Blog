/// Los timestamps sin zona del backend se interpretan como UTC.
DateTime apiDate(String value) {
  final hasZone = RegExp(
    r'(Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  ).hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toUtc();
}

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Se esperaba un objeto JSON.');
  }
  return value;
}

List<T> jsonList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) {
    throw const FormatException('Se esperaba una lista JSON.');
  }
  return List<T>.unmodifiable(value.map((item) => parse(jsonObject(item))));
}
