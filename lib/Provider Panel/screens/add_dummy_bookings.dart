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
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "0Au0X32VlAglDCOHNmY8",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 5)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 28)),
        "location": {
          "latitude": 21.1702,
          "longitude": 72.8311,
          "local": "Katargam, Surat"
        },
        "paymentAmount": 500,
        "paymentMode": "Cash",
        "status": "Pending"
      },
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "sGwqMbPXbadonjgeretNyFIst5i1",
        "serviceId": "6PsjcrE9axCwNuc36uAa",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 7)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 25)),
        "location": {
          "latitude": 19.0760,
          "longitude": 72.8777,
          "local": "Andheri, Mumbai"
        },
        "paymentAmount": 750,
        "paymentMode": "Online",
        "status": "Confirmed"
      },
      {
        "userId": "jslzh88QyqbiMrgvVWbWU7AngD63",
        "providerId": "yri40iFNrFVb0M9vy7qHZWG5ZKH3",
        "serviceId": "6nktV7lgbwMo95Kp6oNn",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 2, 15)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 20)),
        "location": {
          "latitude": 28.7041,
          "longitude": 77.1025,
          "local": "Connaught Place, Delhi"
        },
        "paymentAmount": 1000,
        "paymentMode": "UPI",
        "status": "Completed"
      },
      {
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "86QPKqiZURunQYV6Waye",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 10)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 15)),
        "location": {
          "latitude": 13.0827,
          "longitude": 80.2707,
          "local": "T Nagar, Chennai"
        },
        "paymentAmount": 600,
        "paymentMode": "Cash",
        "status": "Cancelled"
      },
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "sGwqMbPXbadonjgeretNyFIst5i1",
        "serviceId": "CNzckjHtIgrfXEShoTiJ",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 3, 3)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 10)),
        "location": {
          "latitude": 18.5204,
          "longitude": 73.8567,
          "local": "Koregaon Park, Pune"
        },
        "paymentAmount": 1200,
        "paymentMode": "Online",
        "status": "Pending"
      },
      {
        "userId": "jslzh88QyqbiMrgvVWbWU7AngD63",
        "providerId": "yri40iFNrFVb0M9vy7qHZWG5ZKH3",
        "serviceId": "CPiAbxf9gIQtzXS3LVMY",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 2, 8)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 8)),
        "location": {
          "latitude": 12.9716,
          "longitude": 77.5946,
          "local": "MG Road, Bangalore"
        },
        "paymentAmount": 850,
        "paymentMode": "Cash",
        "status": "Confirmed"
      },
      {
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "N1prOUJKjeFnAllWGF1b",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 20)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 5)),
        "location": {
          "latitude": 22.5726,
          "longitude": 88.3639,
          "local": "Salt Lake, Kolkata"
        },
        "paymentAmount": 400,
        "paymentMode": "Online",
        "status": "Completed"
      },
      {
        "userId": "YbQvtIOdbugXZa5Se1yOGLeN9hR2",
        "providerId": "sGwqMbPXbadonjgeretNyFIst5i1",
        "serviceId": "P0tVaLj18IUYbfLsTZpC",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 2, 25)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 12, 1)),
        "location": {
          "latitude": 25.5941,
          "longitude": 85.1376,
          "local": "Fraser Road, Patna"
        },
        "paymentAmount": 950,
        "paymentMode": "UPI",
        "status": "Cancelled"
      },
      {
        "userId": "jslzh88QyqbiMrgvVWbWU7AngD63",
        "providerId": "yri40iFNrFVb0M9vy7qHZWG5ZKH3",
        "serviceId": "TAtMhHo3TOv9bUdWFl3R",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 15)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 11, 28)),
        "location": {
          "latitude": 31.6340,
          "longitude": 74.8723,
          "local": "Golden Temple Area, Amritsar"
        },
        "paymentAmount": 700,
        "paymentMode": "Cash",
        "status": "Pending"
      },
      {
        "userId": "5gB3ecdk9jVm575fuVrAUEKEgFU2",
        "providerId": "kYtEjoImtKW0zmc9ZwcTDgZ6Qpn2",
        "serviceId": "XFjv6laP42Px3tYuoiv8",
        "serviceDate": Timestamp.fromDate(DateTime(2024, 1, 25)),
        "bookingDate": Timestamp.fromDate(DateTime(2023, 11, 25)),
        "location": {
          "latitude": 26.9124,
          "longitude": 75.7873,
          "local": "Malviya Nagar, Jaipur"
        },
        "paymentAmount": 500,
        "paymentMode": "Online",
        "status": "Confirmed"
      },
      // Add more entries as needed with diverse cities
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
        onPressed: addDummyBookings,
        child: const Icon(Icons.add),
      ),
      body: const Center(
        child: Text("Press the button to add dummy bookings."),
      ),
    );
  }
}
