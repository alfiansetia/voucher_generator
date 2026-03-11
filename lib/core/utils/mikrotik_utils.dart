class MikrotikUtils {
  /// Parses Mikrotik uptime string (e.g., "1w2d3h4m5s") into [Duration]
  static Duration parseDuration(String uptime) {
    int weeks = 0;
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    final regex = RegExp(r'(\d+)([wdhms])');
    final matches = regex.allMatches(uptime);

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2)!;
      switch (unit) {
        case 'w':
          weeks = value;
          break;
        case 'd':
          days = value;
          break;
        case 'h':
          hours = value;
          break;
        case 'm':
          minutes = value;
          break;
        case 's':
          seconds = value;
          break;
      }
    }

    return Duration(
      days: weeks * 7 + days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  /// Formats [Duration] into a readable string (e.g., "1w 2d 03:04:05")
  static String formatDuration(Duration duration) {
    int totalSeconds = duration.inSeconds;

    int weeks = totalSeconds ~/ (7 * 24 * 3600);
    totalSeconds %= (7 * 24 * 3600);

    int days = totalSeconds ~/ (24 * 3600);
    totalSeconds %= (24 * 3600);

    int hours = totalSeconds ~/ 3600;
    totalSeconds %= 3600;

    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    List<String> parts = [];
    if (weeks > 0) parts.add('${weeks}w');
    if (days > 0) parts.add('${days}d');

    String timePart =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    if (parts.isEmpty) return timePart;
    return '${parts.join(' ')} $timePart';
  }
}
