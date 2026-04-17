const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Format a DateTime as "Mar 27, 2:58 PM" in the device's local timezone.
String formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final hour = local.hour > 12
      ? local.hour - 12
      : local.hour == 0
          ? 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '${_months[local.month - 1]} ${local.day}, $hour:$minute $amPm';
}

/// Format a DateTime as "Mar 27, 2026" in the device's local timezone.
String formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Format a DateTime as "3/27 2:58pm" in the device's local timezone.
/// Compact format for "last fetched" timestamps.
String formatFetchTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour > 12
      ? local.hour - 12
      : local.hour == 0
          ? 12
          : local.hour;
  final m = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'pm' : 'am';
  return '${local.month}/${local.day} $h:$m$amPm';
}
