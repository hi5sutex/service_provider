// import 'package:location/location.dart';
// import 'package:latlong2/latlong.dart';
//
// class LocationService {
//   static const int LOCATION_UPDATE_INTERVAL = 2000; // milliseconds
//   static const int LOCATION_UPDATE_DISTANCE = 5; // meters
//
//   final Location _location = Location();
//
//   Future<bool> checkAndRequestPermissions() async {
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         return false;
//       }
//     }
//
//     PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         return false;
//       }
//     }
//     return true;
//   }
//
//   Future<void> initializeLocationSettings() async {
//     await _location.changeSettings(
//       accuracy: LocationAccuracy.high,
//       interval: LOCATION_UPDATE_INTERVAL,
//       distanceFilter: LOCATION_UPDATE_DISTANCE,
//     );
//   }
//
//   Stream<LatLng> getLocationStream() {
//     return _location.onLocationChanged.map((locationData) {
//       if (locationData.latitude == null || locationData.longitude == null) {
//         throw Exception('Invalid location data received');
//       }
//       return LatLng(locationData.latitude!, locationData.longitude!);
//     });
//   }
//
//   Future<LatLng?> getCurrentLocation() async {
//     try {
//       LocationData locationData = await _location.getLocation();
//       if (locationData.latitude != null && locationData.longitude != null) {
//         return LatLng(locationData.latitude!, locationData.longitude!);
//       }
//       return null;
//     } catch (e) {
//       print('Error getting current location: $e');
//       return null;
//     }
//   }
// }
