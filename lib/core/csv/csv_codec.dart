/// RFC 4180-style records, including escaped quotes and embedded newlines.
List<List<String>> decodeCsv(String input) {
  final source = input.startsWith('\uFEFF') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false, closed = false;
  void finishField() {
    row.add(field.toString());
    field = StringBuffer();
    closed = false;
  }

  void finishRow() {
    finishField();
    if (row.any((v) => v.trim().isNotEmpty)) rows.add(row);
    row = [];
  }

  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
          closed = true;
        }
      } else {
        field.write(c);
      }
    } else if (c == ',') {
      finishField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
      finishRow();
    } else if (c == '"' && field.isEmpty && !closed) {
      quoted = true;
    } else {
      if (closed || c == '"') {
        throw const FormatException('Aspas inválidas no CSV.');
      }
      field.write(c);
    }
  }
  if (quoted) {
    throw const FormatException('Campo CSV com aspas não encerradas.');
  }
  if (field.isNotEmpty || row.isNotEmpty || closed) finishRow();
  return rows;
}

String encodeCsv(Iterable<List<String>> rows, {bool spreadsheetSafe = true}) =>
    rows
        .map(
          (row) => row
              .map((cell) {
                final value =
                    spreadsheetSafe && RegExp(r'^\s*[=+@-]').hasMatch(cell)
                    ? "'$cell"
                    : cell;
                return '"${value.replaceAll('"', '""')}"';
              })
              .join(','),
        )
        .join('\r\n');
