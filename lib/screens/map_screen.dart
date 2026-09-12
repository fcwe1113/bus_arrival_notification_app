import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../provider_registry.dart';
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
  final Map<String, BitmapDescriptor> _iconCache = {};
  List<BusStop> _stops = [];
  BusStop? selectedStop;
  Set<Polyline> _routePolylines = {};

  Future<BitmapDescriptor> _iconFor(String providerCode) async {
    if (_iconCache.containsKey(providerCode)) {
      return _iconCache["providerCode"]!;
    }

    final provider = availableProviders.firstWhere((p) => p.providerCode == providerCode);
    final icon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(32, 32)), provider.IconAsset);
    _iconCache[providerCode] = icon;
    return icon;
  }

  Future<Set<Marker>> _buildMarkers() async {
    final markers = <Marker>{};
    for (final stop in _stops) {
      if (!stop.isResolved) continue;
      final icon = _iconFor(stop.providerCode);
      markers.add(Marker(markerId: MarkerId(stop.id), position: LatLng(stop.lat!, stop.lng!), icon: await icon, onTap: () => _onStopTapped(stop)));
    }
    return markers;
  }

  void _onStopTapped(BusStop stop) async {
    // todo Placeholder — actual implementation needs the route-stop endpoint
    throw UnimplementedError();
    // final routeStops = await kmbProvider.fetchRouteStopSequence(routeId, bound);
    // final points = routeStops
    //     .where((s) => s.isResolved)
    //     .map((s) => LatLng(s.lat!, s.lng!))
    //     .toList();
    //
    // setState(() {
    //   _routePolylines = {
    //     Polyline(
    //       polylineId: PolylineId(routeId),
    //       points: points,
    //       color: Colors.blue,
    //       width: 4,
    //     ),
    //   };
    // });
  }

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