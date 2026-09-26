String formatPhone(dynamic value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) return '—';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('258') && digits.length == 12
      ? digits.substring(3)
      : digits;
  if (local.length == 9 && RegExp(r'^8[2-7]\d{7}$').hasMatch(local)) {
    return '+258 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
  }
  if (digits.length >= 10 && raw.startsWith('+')) return raw;
  return raw;
}
