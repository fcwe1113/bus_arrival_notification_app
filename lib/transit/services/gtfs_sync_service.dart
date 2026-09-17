import 'package:archive/archive.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

abstract class GtfsSyncProvider {
  String get locale;
  String get feedUrl;
  Future<void> syncFeed({ProgressCallback? onProgress});
  Future<bool> checkIsStale();
}

class GtfsSyncService {
  final String locale;
  late final GtfsDatabase _db;

  GtfsSyncService({required this.locale}) {
    _db = GtfsDatabase.forLocale(locale);
  }

  Future<void> parseAndStoreGtfsArchive(Archive archive, {ProgressCallback? onProgress}) async {
    final validFiles = archive.where((f) => f.isFile).toList();
    final totalFiles = validFiles.length;
    int processedCount = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      final fileName = p.basename(file.name);
      final stepProgress = 0.5 + (0.45 * (processedCount / totalFiles));
      onProgress?.call("Parsing ${fileName}...", stepProgress);

      final content = String.fromCharCodes(file.content as List<int>);
      final csvData = CsvDecoder().convert(content);

      switch (fileName) {
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
      processedCount++;
    }
  }
}