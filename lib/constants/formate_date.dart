String formatDate(DateTime date) {
  // if today
  if (date.day == DateTime.now().day &&
      date.month == DateTime.now().month &&
      date.year == DateTime.now().year) {
    // Today 10:50
    return 'Today ${date.hour > 9 ? date.hour : '0${date.hour}'}:${date.minute > 9 ? date.minute : '0${date.minute}'}';
  }

  // if yesterday
  if (date.day == DateTime.now().day - 1 &&
      date.month == DateTime.now().month &&
      date.year == DateTime.now().year) {
    // Yesterday 10:50
    return 'Yesterday ${date.hour > 9 ? date.hour : '0${date.hour}'}:${date.minute > 9 ? date.minute : '0${date.minute}'}';
  }
//  10/01/2024 10:50
  return '${date.day}/${date.month}/${date.year} ${date.hour > 9 ? date.hour : '0${date.hour}'}:${date.minute > 9 ? date.minute : '0${date.minute}'}';
}
