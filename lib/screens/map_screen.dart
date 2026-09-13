import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';
import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../provider_registry.dart';
import '../widgets/app_shell.dart';
import '../widgets/stop_routes_sheet.dart';

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
  Map<String, BusRoute> _routesById = {};
  Set<Marker> _markers = {};
  Set<Marker> _visibleMarkers = {};
  bool _loading = true;
  BusStop? selectedStop;
  final Set<Polyline> _routePolylines = {};

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final allStops = <BusStop>[];
    final allRoutes = <BusRoute>[];

    for (final provider in availableProviders) {
      if (provider is KmbProvider) {
        allStops.addAll((await provider.buildStopsWithRoutes()) as Iterable<BusStop>); // todo check
      } else {
        allStops.addAll(await provider.fetchStops());
      }
      allRoutes.addAll(await provider.fetchRoutes());
    }

    final routesById = {for (final r in allRoutes) r.id: r};
    final markers = await _buildMarkers(allStops);

    setState(() {
      _stops = allStops;
      _routesById = routesById;
      _markers = markers;
      _loading = false;

    });
  }

  Future<BitmapDescriptor> _iconFor(String providerCode) async {
    if (_iconCache.containsKey(providerCode)) return _iconCache[providerCode]!;
    final provider = availableProviders.firstWhere((p) => p.providerCode == providerCode);
    final icon = await BitmapDescriptor.asset(const ImageConfiguration(), provider.IconAsset);
    _iconCache[providerCode] = icon;
    return icon;
  }

  Future<Set<Marker>> _buildMarkers(List<BusStop> stops) async {
    final markers = <Marker>{};
    for (final stop in stops) {
      if (!stop.isResolved) continue;
      final icon = _iconFor(stop.providerCode);
      markers.add(Marker(markerId: MarkerId(stop.id), position: LatLng(stop.lat!, stop.lng!), icon: await icon, onTap: () => _onStopTapped(stop)));
    }
    return markers;
  }

  void _onStopTapped(BusStop stop) async {
    final servingRoutes = stop.servingRouteIds.map((id) => _routesById[id]).whereType<BusRoute>().toList();
    showModalBottomSheet(context: context, builder: (context) => StopRoutesSheet(stop: stop, routes: servingRoutes));
  }

  Future<void> _updateVisibleMarkers() async {
    if (_mapController == null) return;

    final bounds = await _mapController!.getVisibleRegion();
    final visibleStops = _stops.where((stop) {
      if (!stop.isResolved) return false;
      return bounds.contains(LatLng(stop.lat!, stop.lng!));
    }).toList();

    // hard cap the stops displayed within the visible area
    final cappedStops = visibleStops.take(50).toList();
    final markers = await _buildMarkers(cappedStops);
    setState(() => _visibleMarkers = markers);
  }

  // initial position of the map on load, currently on london, replace with user settings later
  // static const _initialPosition = CameraPosition(target: LatLng(51.5072, -0.1276), zoom: 13);

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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(),),);
    }
    return AppShell(
      title: "Map",
      body: GoogleMap(
        // key: UniqueKey(),
        initialCameraPosition: const CameraPosition(target: LatLng(22.3193, 114.1694), zoom: 12),
        onMapCreated: (controller) {
          _mapController = controller;
          _updateVisibleMarkers();
        },
          onCameraIdle: _updateVisibleMarkers,
        myLocationEnabled: true, // enables phone location services
        markers: _visibleMarkers
      ),
    );
  }
}