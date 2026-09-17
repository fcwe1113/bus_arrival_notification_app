import 'package:archive/archive.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

abstract class GtfsSyncProvider {
  String get localeId;
  String get feedUrl;
  Future<void> syncFeed();
}

class GtfsSyncService {
  final String locale;
  late final GtfsDatabase _db;

  GtfsSyncService({required this.locale}) {
    _db = GtfsDatabase.forLocale(locale);
  }

  Future<void> parseAndStoreGtfsArchive(Archive archive) async {
    for (final file in archive) {
      if (!file.isFile) continue;
      final content = String.fromCharCodes(file.content as List<int>);
      final csvData = CsvDecoder().convert(content);

      switch (p.basename(file.name)) {
        case "routes.txt":
          await _db.batchInsertRoutes(csvData);
          break;
        case "trips.txt":
          await _db.batchInsertTrips(csvData);
          break;
        case "calendar.txt":
          await _db.batchInsertCalendar(csvData);
          break;
        case "stop_times.txt":
          await _db.batchInsertStopTimes(csvData);
          break;
      }
    }
  }
}