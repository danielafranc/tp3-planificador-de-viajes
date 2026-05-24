const _shortMonths = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const _capitalizedMonths = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

String formatMonthYearShort(DateTime date) {
  return '${_shortMonths[date.month - 1]} ${date.year}';
}

String formatMonthYear(DateTime date) {
  return '${_capitalizedMonths[date.month - 1]} ${date.year}';
}

String formatMonthKey(String yearMonthKey) {
  final parts = yearMonthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return '${_capitalizedMonths[month - 1]} $year';
}
