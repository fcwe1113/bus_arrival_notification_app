// bus stop data struct definition file

class BusStop {
  final String id; // composited into providerCode:id
  final Map<String, String> names; // {"lang1": "name1", "lang2": "name2", ...}, defaults to "en"
  final double? lat;
  final double? lng;
  final String providerCode;

  const BusStop({
    required this.id,
    required this.names,
    this.lat,
    this.lng,
    required this.providerCode
  });

  String nameFor(String locale) => names[locale] ?? names["en"] ?? id;

  // special constructor for a placeholder stop object where only the name is known
  BusStop.placeholder({
    required String id,
    required String name,
    required String providerCode,
  }) : this(
      id: id,
      names: {"en": name},
      providerCode: providerCode,
  );

  bool get isResolved => lat != null && lng != null;
}