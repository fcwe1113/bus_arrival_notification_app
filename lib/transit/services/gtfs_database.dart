import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GtfsDatabase {
  static final GtfsDatabase instance = GtfsDatabase._init();
  static Database? _database;

  GtfsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("gtfs_schedule.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE gtfs_routes (route_id TEXT PRIMARY KEY, route_short_name TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE gtfs_trips (
    trip_id TEXT PRIMARY KEY, route_id TEXT NOT NULL, service_id TEXT NOT NULL, direction_id INTEGER)''');
    await db.execute('''CREATE TABLE gtfs_calendar (service_id TEXT PRIMARY KEY, 
    monday INTEGER, tuesday INTEGER, wednesday INTEGER, thursday INTEGER, friday INTEGER, saturday INTEGER, sunday INTEGER,
    start_date TEXT, end_date TEXT)''');
    await db.execute('''CREATE TABLE gtfs_stop_times (trip_id TEXT NOT NULL, 
    arrival_time TEXT NOT NULL, departure_time TEXT NOT NULL, stop_id TEXT NOT NULL, stop_sequence INTEGER NOT NULL)''');

    await db.execute('''CREATE INDEX idx_routes_name ON gtfs_routes(route_short_name)''');
    await db.execute('''CREATE INDEX idx_trips_route_service ON gtfs_trips(route_id, service_id)''');
    await db.execute('''CREATE INDEX idx_stop_times_lookup ON gtfs_stop_times(stop_id, arrival_time)''');
  }

  String _val(List<dynamic> row, int index) => row.length > index ? row[index].toString() : "";

  Future<void> batchInsertRoutes(List<List<dynamic>> rows) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var row in rows.skip(1)){
        batch.insert("gtfs_routes", {
          "route_id": _val(row, 0),
          "route_short_name": _val(row, 2)
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> batchInsertTrips(List<List<dynamic>> rows) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var row in rows.skip(1)){
        batch.insert("gtfs_trips", {
          "route_id": _val(row, 0),
          "service_id": _val(row, 1),
          "trip_id": _val(row, 2),
          "direction_id": int.tryParse(_val(row, 5)) ?? 0
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> batchInsertCalendar(List<List<dynamic>> rows) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var row in rows.skip(1)){
        batch.insert("gtfs_calendar", {
          "service_id": _val(row, 0),
          "monday": int.tryParse(_val(row, 1)) ?? 0,
          "tuesday": int.tryParse(_val(row, 2)) ?? 0,
          "wednesday": int.tryParse(_val(row, 3)) ?? 0,
          "thursday": int.tryParse(_val(row, 4)) ?? 0,
          "friday": int.tryParse(_val(row, 5)) ?? 0,
          "saturday": int.tryParse(_val(row, 6)) ?? 0,
          "sunday": int.tryParse(_val(row, 7)) ?? 0,
          "start_date": _val(row, 8),
          "end_date": _val(row, 9)
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> batchInsertStopTimes(List<List<dynamic>> rows) async {
    final db = await instance.database;
    await db?.transaction((txn) async {
      final batch = txn.batch();
      for (var row in rows.skip(1)){
        batch.insert("gtfs_stop_times", {
          "trip_id": _val(row, 0),
          "arrival_time": _val(row, 1),
          "departure_time": _val(row, 2),
          "stop_id": _val(row, 3),
          "stop_sequence": int.tryParse(_val(row, 4)) ?? 0
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<String>?> getScheduledArrivals({required String stopId, required String routeShortName, required DateTime targetTime}) async {
    final db = await instance.database;

    final weekDays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];
    final currentDayColumn = weekDays[targetTime.weekday - 1];

    final timeStr = "${targetTime.hour.toString().padLeft(2, "0")}:${targetTime.minute.toString().padLeft(2, "0")}:${targetTime.second.toString().padLeft(2, "0")}";
    final dateStr = "${targetTime.year}${targetTime.month.toString().padLeft(2, "0")}${targetTime.day.toString().padLeft(2, "0")}";

    final List<Map<String, dynamic>>? results = await db?.rawQuery('''
    SELECT st.arrival_time
    from gtfs_stop_times st
    INNER JOIN gtfs_trips t ON st.trip_id = t.trip_id
    INNER JOIN gtfs_routes r ON t.route_id = r.route_id
    INNER JOIN gtfs_calendar c ON t.service_id = c.service_id
    WHERE st.stop_id = ?
      AND r.route_short_name = ?
      AND st.arrival_time >= ?
      AND c.$currentDayColumn = 1
      AND c.start_date <= ?
      AND c.end_date >= ?
    ORDER BY st.arrival_time ASC
    LIMIT 5
    ''', [stopId, routeShortName, timeStr, dateStr, dateStr]);

    return results?.map((r) => r["arrival_time"] as String).toList();
  }
}