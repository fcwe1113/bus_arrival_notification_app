class LocaleConfig {
  final String code;
  final String displayName;
  final Duration utcOffset;

  const LocaleConfig({required this.code, required this.displayName, required this.utcOffset});

  DateTime nowInLocale() => DateTime.now().toUtc().add(utcOffset);
}