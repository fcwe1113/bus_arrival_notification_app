import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/app_shell.dart';

// todo adapt this screen into future add new alarm process

/// StatefulWidget wrapper for the map screen
class MapScreen extends StatefulWidget { // statefulwidgets are widgets that can have modifiable internal data, they contain an immutable Widget and a mutable State object within
  const MapScreen({super.key});

  @override // this is a requirement for any statefulwidget
  State<MapScreen> createState() => _MapScreenState(); // MapScreen being the immutable widget and _MapScreenState() being the mutable state
}

/// State object within the map screen
class _MapScreenState extends State<MapScreen> {
  // here State<MapScreen> DOES NOT mean a state object of a mapscreen type ala c#
  // instead it is extending the underlying State<T> and hooking up this state to the mapscreen widget

  GoogleMapController? _mapController;
  static const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  // initial position of the map on load, currently on london, replace with user settings later
  static const _initialPosition = CameraPosition(target: LatLng(51.5072, -0.1276), zoom: 13);

  @override // this is a requirement for any state object
  Widget build(BuildContext context) {
    // when build gets called the widget refreshes, and the statefulwidget is destroyed and rebuilt
    // there are a few ways to proc build()
    // 1. on first build
    // 2. with setState()
    // 3. rebuilding the parent widget
    // 4. hot reload in dev mode (but thats cheating)
    // for the "refresh after api pull" effect put in a setState() in the same function as the api call and put it after the api call line
    // if real time updates needed try StreamBuilder

    return AppShell(
      title: "Map",
      body: GoogleMap(
        // key: UniqueKey(),
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true, // enables phone location services
        markers: {
          Marker(
            markerId: MarkerId("bus_1"),
            position: LatLng(51.5072, -0.1276),
          ),
        },
      ),
    );
  }
}