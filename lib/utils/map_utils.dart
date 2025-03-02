// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'dart:math' as math;
//
// class MapUtils {
//   static const int TILE_CACHE_CAPACITY = 200;
//   static const double MIN_ZOOM = 5.0;
//   static const double MAX_ZOOM = 18.0;
//   static const double DEFAULT_ZOOM = 15.0;
//
//   static TileLayer getOptimizedTileLayer() {
//     return TileLayer(
//       urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//       subdomains: const ['a', 'b', 'c'],
//       userAgentPackageName: 'com.example.app',
//       tileProvider: NetworkTileProvider(),
//       maxZoom: MAX_ZOOM,
//       minZoom: MIN_ZOOM,
//       tileBuilder: (context, child, tile) {
//         return TileWidget(
//           tile: tile,
//           child: child,
//         );
//       },
//       keepBuffer: 5,
//       backgroundColor: const Color(0xFFE0E0E0),
//     );
//   }
//
//   static MapOptions getOptimizedMapOptions(LatLng initialCenter) {
//     return MapOptions(
//       initialCenter: initialCenter,
//       initialZoom: DEFAULT_ZOOM,
//       minZoom: MIN_ZOOM,
//       maxZoom: MAX_ZOOM,
//       interactionOptions: const InteractionOptions(
//         flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
//         enableScrollWheel: true,
//         scrollWheelVelocity: 0.005,
//       ),
//       keepAlive: true,
//       enableScrollWheel: true,
//       adaptiveBoundaries: true,
//       onMapReady: () {
//         print('Map is ready');
//       },
//       onPositionChanged: (MapPosition position, bool hasGesture) {
//         // Handle position changes if needed
//       },
//     );
//   }
//
//   static double calculateBearing(LatLng start, LatLng end) {
//     double startLat = start.latitude * (math.pi / 180);
//     double startLng = start.longitude * (math.pi / 180);
//     double endLat = end.latitude * (math.pi / 180);
//     double endLng = end.longitude * (math.pi / 180);
//
//     double dLng = endLng - startLng;
//
//     double y = math.sin(dLng) * math.cos(endLat);
//     double x = math.cos(startLat) * math.sin(endLat) -
//         math.sin(startLat) * math.cos(endLat) * math.cos(dLng);
//
//     double bearing = math.atan2(y, x);
//     bearing = bearing * (180 / math.pi);
//     bearing = (bearing + 360) % 360;
//
//     return bearing;
//   }
// }
//
// class TileWidget extends StatelessWidget {
//   final Tile tile;
//   final Widget child;
//
//   const TileWidget({
//     Key? key,
//     required this.tile,
//     required this.child,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedOpacity(
//       opacity: 1.0,
//       duration: const Duration(milliseconds: 300),
//       child: child,
//     );
//   }
// }
