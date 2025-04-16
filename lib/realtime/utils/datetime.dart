
String formatDateString(String dateString) {
  // Extract the day (characters 8 and 9)
  final day = dateString.substring(8, 10);

  // Extract the month (characters 5 and 6)
  final month = dateString.substring(5, 7);

  // Combine the extracted parts in the desired format
  return '$day/$month';
}

String formatDatetimeString(String dateString) {
  // Extract the day (characters 8 and 9)
  final day = dateString.substring(8, 10);

  // Extract the month (characters 5 and 6)
  final month = dateString.substring(5, 7);

  // Extract the hour (characters 11 and 12)
  final hour = dateString.substring(11, 13);

  // Extract the minute (characters 14 and 15)
  final minute = dateString.substring(14, 16);

  // Combine the extracted parts in the desired format
  return '$day/$month - $hour:$minute';
}