class ScheduledDeparture {
  final String routeShortName;
  final String arrivalTime; // in "HH:MM:SS"
  final int? directionId;

  const ScheduledDeparture ({required this.routeShortName, required this.arrivalTime, this.directionId});

  int get minutesFromNow {
    final parts = arrivalTime.split(":");
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final now = DateTime.now().toUtc().add(const Duration(hours: 8)); // accounting for local gmt+8
    final serviceDayStart = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
    final scheduledDateTime = serviceDayStart.add(Duration(hours: hours, minutes: minutes));

    return scheduledDateTime.difference(now).inMinutes;
  }
}