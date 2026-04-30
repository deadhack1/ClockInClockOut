DateTime startOfWeek(DateTime date){
  final d = DateTime(date.year,date.month,date.day);
  return d.subtract(Duration(days:d.weekday-1));
}