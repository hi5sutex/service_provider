import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveTrackingPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const LiveTrackingPage({
    required this.bookingId,
    required this.bookingData,
    Key? key,
  }) : super(key: key);

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  MapController mapController = MapController();
  Location location = Location();
  LocationData? currentLocationData;
  latlong.LatLng? currentLocation;
  StreamSubscription<LocationData>? locationSubscription;

  latlong.LatLng? destinationLocation;
  List<latlong.LatLng> routeCoordinates = [];

  String estimatedTime = "Calculating...";
  String estimatedDistance = "Calculating...";

  DateTime? lastRouteUpdate;
  bool isTrackingStarted = false; // Flag to control live tracking

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Booking Data: ${widget.bookingData}');
      extractDestinationLocation();
      getInitialLocation(); // Fetch initial location without starting live tracking
    });
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  void extractDestinationLocation() {
    if (widget.bookingData.containsKey('location') && widget.bookingData['location'] is Map) {
      final loc = widget.bookingData['location'] as Map;
      if (loc.containsKey('latitude') && loc.containsKey('longitude')) {
        destinationLocation = latlong.LatLng(loc['latitude'], loc['longitude']);
      }
    } else if (widget.bookingData.containsKey('location') && widget.bookingData['location'] is GeoPoint) {
      GeoPoint geoPoint = widget.bookingData['location'];
      destinationLocation = latlong.LatLng(geoPoint.latitude, geoPoint.longitude);
    }
    print('Destination Location: $destinationLocation');
    if (destinationLocation == null) {
      showErrorAndNavigateBack('No valid customer location found in booking data');
    }
  }

  void getInitialLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        showErrorAndNavigateBack("Location services are disabled");
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        showErrorAndNavigateBack("Location permission denied");
        return;
      }
    }

    try {
      currentLocationData = await location.getLocation();
      setState(() {
        currentLocation = latlong.LatLng(
          currentLocationData!.latitude!,
          currentLocationData!.longitude!,
        );
        print('Initial Current Location: $currentLocation');
      });

      getOSRMRoute(); // Show initial route without live tracking
    } catch (e) {
      print('Error getting initial location: $e');
      showErrorAndNavigateBack('Failed to get location: $e');
    }
  }

  void startLiveTracking() async {
    if (isTrackingStarted) return; // Prevent multiple subscriptions

    try {
      locationSubscription = location.onLocationChanged.listen((LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          setState(() {
            currentLocationData = locationData;
            currentLocation = latlong.LatLng(locationData.latitude!, locationData.longitude!);
            print('Updated Current Location: $currentLocation');
          });

          if (lastRouteUpdate == null || DateTime.now().difference(lastRouteUpdate!).inSeconds > 5) {
            getOSRMRoute();
            lastRouteUpdate = DateTime.now();
          }
          updateProviderLocationInFirestore();

          mapController.move(currentLocation!, mapController.camera.zoom);
        }
      });
      setState(() {
        isTrackingStarted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live tracking started')),
      );
    } catch (e) {
      print('Error starting live tracking: $e');
      showErrorAndNavigateBack('Failed to start live tracking: $e');
    }
  }

  void updateProviderLocationInFirestore() async {
    if (currentLocation == null) return;

    try {
      String providerId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'providerCurrentLocation': GeoPoint(currentLocation!.latitude, currentLocation!.longitude),
        'lastLocationUpdate': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('providers').doc(providerId).update({
        'currentLocation': GeoPoint(currentLocation!.latitude, currentLocation!.longitude),
        'lastLocationUpdate': Timestamp.now(),
      });
      print('Location updated in Firestore');
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  Future<void> getOSRMRoute() async {
    if (currentLocation == null || destinationLocation == null) {
      print('Cannot fetch route: currentLocation or destinationLocation is null');
      routeCoordinates = currentLocation != null && destinationLocation != null
          ? [currentLocation!, destinationLocation!]
          : [];
      calculateEstimatedTimeAndDistanceFallback();
      return;
    }

    final url = 'http://router.project-osrm.org/route/v1/driving/'
        '${currentLocation!.longitude},${currentLocation!.latitude};'
        '${destinationLocation!.longitude},${destinationLocation!.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
        routeCoordinates = coordinates.map((coord) => latlong.LatLng(coord[1], coord[0])).toList();

        double distanceInMeters = data['routes'][0]['distance'];
        double durationInSeconds = data['routes'][0]['duration'];
        double distanceInKm = distanceInMeters / 1000;
        int durationInMinutes = (durationInSeconds / 60).round();

        setState(() {
          estimatedDistance = '${distanceInKm.toStringAsFixed(2)} km';
          estimatedTime = durationInMinutes <= 1 ? 'About 1 minute' : 'About $durationInMinutes minutes';
          print('OSRM Route Distance: $estimatedDistance, Time: $estimatedTime');
        });
      } else {
        print('Error fetching OSRM route: ${response.statusCode} - ${response.body}');
        routeCoordinates = [currentLocation!, destinationLocation!];
        calculateEstimatedTimeAndDistanceFallback();
      }
    } catch (e) {
      print('Error getting OSRM route: $e');
      routeCoordinates = [currentLocation!, destinationLocation!];
      calculateEstimatedTimeAndDistanceFallback();
    }
  }

  void calculateEstimatedTimeAndDistanceFallback() async {
    if (currentLocation == null || destinationLocation == null) return;

    double distanceInMeters = await calculateDistance(
      currentLocation!.latitude,
      currentLocation!.longitude,
      destinationLocation!.latitude,
      destinationLocation!.longitude,
    );

    double distanceInKm = distanceInMeters / 1000;
    double timeInHours = distanceInKm / 40;
    int timeInMinutes = (timeInHours * 60).round();

    setState(() {
      estimatedDistance = '${distanceInKm.toStringAsFixed(2)} km';
      estimatedTime = timeInMinutes <= 1 ? 'About 1 minute' : 'About $timeInMinutes minutes';
      print('Fallback Distance: $estimatedDistance, Time: $estimatedTime');
    });
  }

  Future<double> calculateDistance(double startLat, double startLng, double endLat, double endLng) async {
    const int earthRadius = 6371000;
    double lat1 = startLat * (math.pi / 180);
    double lat2 = endLat * (math.pi / 180);
    double lng1 = startLng * (math.pi / 180);
    double lng2 = endLng * (math.pi / 180);

    double dLat = lat2 - lat1;
    double dLng = lng2 - lng1;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void showErrorAndNavigateBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  void markAsArrived() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'providerArrived': true,
        'status': 'Completed',
        'completedAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service completed and marked as arrived')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete service: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: const Color(0xFF060644),
      ),
      body: Stack(
        children: [
          if (currentLocation == null)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation!,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
                    ),
                    if (destinationLocation != null)
                      Marker(
                        point: destinationLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                  ],
                ),
                if (routeCoordinates.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routeCoordinates,
                        strokeWidth: 5.0,
                        color: const Color(0xFF060644),
                      ),
                    ],
                  ),
              ],
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Navigating to Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF060644),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF060644)),
                          const SizedBox(height: 4),
                          Text(
                            'Est. Time',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            estimatedTime,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.directions_car, color: Color(0xFF060644)),
                          const SizedBox(height: 4),
                          Text(
                            'Distance',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            estimatedDistance,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isTrackingStarted ? markAsArrived : startLiveTracking, // Toggle between starting tracking and marking arrival
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF060644),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isTrackingStarted ? 'Mark as Arrived' : 'Go to Destination',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Booking', style: TextStyle(color: Color(0xFF060644))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}