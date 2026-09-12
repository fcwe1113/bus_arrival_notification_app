import 'package:bus_arrival_notification_app/screens/alarm_list_screen.dart';
import 'package:bus_arrival_notification_app/screens/map_screen.dart';
import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async { // dart entry point

  // WidgetsFlutterBinding.ensureInitialized();
  // final cache = TransitCacheService();
  // final kmb = KmbProvider(cache);
  // final stops = await kmb.fetchStops();
  // print('Fetched ${stops.length} stops');
  // print(stops.first.names);

  runApp(const MyApp()); // app entry point, working with flutter from this point on
}

class MyApp extends StatelessWidget { // statelesswidget only has constant internal data
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: "/", // indicate which route to show on boot
      routes: { // list of screens with the routes linked to it
        "/": (context) => const AlarmListScreen(),
        "/map": (context) => const MapScreen(),
        // add more routes here as we add more screens
      },
    );
  }
}