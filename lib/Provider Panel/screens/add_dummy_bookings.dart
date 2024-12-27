import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDummyBookings extends StatefulWidget {
  const AddDummyBookings({super.key});

  @override
  State<AddDummyBookings> createState() => _AddDummyBookingsState();
}

class _AddDummyBookingsState extends State<AddDummyBookings> {

  void addDummyBookings() async {
    final bookings = [
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "6PsjcrE9axCwNuc36uAa",
        "serviceDate": "2025-01-10T10:30:00Z",
        "paymentAmount": 1500,
        "paymentMode": "Online",
        "status": "Confirmed",
        "location": {
          "latitude": 22.3072,
          "longitude": 73.1812,
          "local": "Vadodara, Gujarat, India"
        },
        "bookingDate": "2024-12-27T14:15:00Z"
      },
      {
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "qW3XeIGyom8KWbJeTBUA",
        "serviceDate": "2025-01-15T15:00:00Z",
        "paymentAmount": 2200,
        "paymentMode": "Cash",
        "status": "Pending",
        "location": {
          "latitude": 21.1702,
          "longitude": 72.8311,
          "local": "Surat, Gujarat, India"
        },
        "bookingDate": "2024-12-25T13:00:00Z"
      },
      {
        "userId": "jslzh88QyqbiMrgvVWbWU7AngD63",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "oILamNOtm9c03W8Gltzd",
        "serviceDate": "2025-01-20T11:00:00Z",
        "paymentAmount": 1800,
        "paymentMode": "Online",
        "status": "Completed",
        "location": {
          "latitude": 23.0225,
          "longitude": 72.5714,
          "local": "Ahmedabad, Gujarat, India"
        },
        "bookingDate": "2024-12-20T12:00:00Z"
      },
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "86QPKqiZURunQYV6Waye",
        "serviceDate": "2025-01-05T09:00:00Z",
        "paymentAmount": 3000,
        "paymentMode": "Card",
        "status": "Cancelled",
        "location": {
          "latitude": 20.5937,
          "longitude": 78.9629,
          "local": "Nagpur, Maharashtra, India"
        },
        "bookingDate": "2024-12-23T10:45:00Z"
      },
      {
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "CNzckjHtIgrfXEShoTiJ",
        "serviceDate": "2025-02-12T14:00:00Z",
        "paymentAmount": 1200,
        "paymentMode": "Online",
        "status": "Confirmed",
        "location": {
          "latitude": 19.0760,
          "longitude": 72.8777,
          "local": "Mumbai, Maharashtra, India"
        },
        "bookingDate": "2024-12-22T16:30:00Z"
      },
      {
        "userId": "jslzh88QyqbiMrgvVWbWU7AngD63",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "ZkMhXew0vXZjfnmoXX8J",
        "serviceDate": "2025-01-18T10:00:00Z",
        "paymentAmount": 2500,
        "paymentMode": "Cash",
        "status": "Completed",
        "location": {
          "latitude": 17.3850,
          "longitude": 78.4867,
          "local": "Hyderabad, Telangana, India"
        },
        "bookingDate": "2024-12-24T15:00:00Z"
      },
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "fvN1QwYPoEwxNE39hIvS",
        "serviceDate": "2025-02-01T12:00:00Z",
        "paymentAmount": 1700,
        "paymentMode": "Online",
        "status": "Pending",
        "location": {
          "latitude": 13.0827,
          "longitude": 80.2707,
          "local": "Chennai, Tamil Nadu, India"
        },
        "bookingDate": "2024-12-21T11:30:00Z"
      },
      {
        "userId": "4wB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "hX9AMnQLyuoapknc9H5v",
        "serviceDate": "2025-01-12T09:00:00Z",
        "paymentAmount": 2000,
        "paymentMode": "Online",
        "status": "Processing",
        "location": {
          "latitude": 12.9716,
          "longitude": 77.5946,
          "local": "Bangalore, Karnataka, India"
        },
        "bookingDate": "2024-12-26T11:00:00Z"
      },
      {
        "userId": "7gB3ecdk9jVm575fuVrAUEKEgFU3",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "pywEkeq71hcV4RyoijF7",
        "serviceDate": "2025-01-30T16:00:00Z",
        "paymentAmount": 1700,
        "paymentMode": "Online",
        "status": "Failed",
        "location": {
          "latitude": 11.0168,
          "longitude": 76.9558,
          "local": "Coimbatore, Tamil Nadu, India"
        },
        "bookingDate": "2024-12-29T09:00:00Z"
      },
      {
        "userId": "8gB3ecdk9jVm575fuVrAUEKEgFU4",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "wq4Ph1MN4jr6o4m9UJh5",
        "serviceDate": "2025-02-05T08:30:00Z",
        "paymentAmount": 2500,
        "paymentMode": "Cash",
        "status": "Cancelled",
        "location": {
          "latitude": 10.8505,
          "longitude": 76.2711,
          "local": "Trivandrum, Kerala, India"
        },
        "bookingDate": "2024-12-30T14:45:00Z"
      }
    ];

    try {
      for (var booking in bookings) {
        await FirebaseFirestore.instance.collection("bookings").add(booking);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bookings added successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add bookings: $e")),
      );
    }

    print("Bookings added successfully!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Dummy Bookings")),
      floatingActionButton: FloatingActionButton(
        onPressed: addDummyBookings, // Removed 'const' and added the proper method call
        child: const Icon(Icons.add),
      ),
      body: const Center(
        child: Text("Press the button to add dummy bookings."),
      ),
    );
  }
}
