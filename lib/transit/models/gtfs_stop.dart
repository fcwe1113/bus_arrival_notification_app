class GtfsStop {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const GtfsStop({required this.id, required this.name, required this.lat, required this.lng});

  static List<String> extractNameFragments(String rawName) {
    return rawName.split("|").expand((segment) => segment.split(RegExp(r"<BR>|/", caseSensitive: false)))
        .map((f) => f.replaceAll(RegExp(r"^\[.*?\]\s*"), "").trim()).where((f) => f.isNotEmpty).toSet().toList();
  }

  static String cleanStopName(String rawName) {
    final fragments = extractNameFragments(rawName);

    if (fragments.isEmpty) return rawName;
    fragments.sort((a, b) => b.length.compareTo(a.length));
    return fragments.first;
  }

  static String normalizeForMatching(String name) {
    return name.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]"), "");
  }
}