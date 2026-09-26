int intValue(dynamic value) =>
    value is int ? value : int.parse(value.toString());

int moneyInput(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(normalized)) {
    throw const FormatException(
      'Use um montante positivo com até duas casas decimais, sem separador de milhares.',
    );
  }
  final parts = normalized.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

String money(dynamic value) {
  final cents = intValue(value ?? 0), positive = intValue(value ?? 0).abs();
  final whole = (positive ~/ 100).toString();
  final groups = <String>[];
  for (var end = whole.length; end > 0; end -= 3) {
    groups.insert(0, whole.substring((end - 3).clamp(0, end), end));
  }
  return '${cents < 0 ? '-' : ''}${groups.join(' ')},${(positive % 100).toString().padLeft(2, '0')} MT';
}
