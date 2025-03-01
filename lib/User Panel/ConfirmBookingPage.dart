import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ConfirmBookingPage extends StatefulWidget {
  final DateTime date;
  final TimeOfDay time;
  final String serviceId;
  final Map<String, dynamic> serviceData;

  ConfirmBookingPage({
    required this.date,
    required this.time,
    required this.serviceData,
    required this.serviceId,
  });



  @override
  _ConfirmBookingPageState createState() => _ConfirmBookingPageState();
}

class _ConfirmBookingPageState extends State<ConfirmBookingPage> {
  TextEditingController addressController = TextEditingController();
  String selectedPaymentMethod = 'Debit Card';
  double taxRate = 0.11; // 11% tax
  double platformFeeRate = 0.01; // 1% platform fee
  double? _latitude;
  double? _longitude;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  double get servicePrice => widget.serviceData['price'] ?? 0.0;
  String get providerId => widget.serviceData['createdBy'] ?? '';
  String get serviceId => widget.serviceId;

  // Razorpay instance
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Listen to address field changes to enable/disable button
    addressController.addListener(() {
      setState(() {}); // Rebuild UI when address changes
    });
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear(); // Clear Razorpay listeners
    addressController.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool filled = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: filled,
        fillColor: filled ? Colors.grey.shade100 : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 0,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permission permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;

      String address = await _getHumanReadableAddress(_latitude!, _longitude!);
      setState(() {
        addressController.text = address;
      });
    } catch (e) {
      _showSnackBar("Error fetching location: $e");
    }
    setState(() => isLoading = false);
  }

  Future<String> _getHumanReadableAddress(double lat, double lon) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? "Unknown Location";
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
    return "Error fetching address";
  }

  double calculateTaxAmount() {
    return servicePrice * taxRate;
  }

  double calculatePlatformFee() {
    return servicePrice * platformFeeRate;
  }

  double calculateTotalAmount() {
    double taxAmount = calculateTaxAmount();
    double platformFee = calculatePlatformFee();
    return servicePrice + taxAmount + platformFee;
  }

  void _openRazorpayCheckout() {
    var options = {
      'key': 'rzp_test_8MwbMjCkPlKzhh', // Replace with your Razorpay Test Key ID
      'amount': (calculateTotalAmount() * 100).toInt(), // Amount in paise
      'name': 'Service Booking',
      'description': 'Payment for ${widget.serviceData['name'] ?? 'Service'}',
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showSnackBar("Error opening Razorpay: $e");
      setState(() => isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _showSnackBar("Payment Successful! Payment ID: ${response.paymentId}");
    _saveBooking(response.paymentId); // Save booking after successful payment
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackBar("Payment Failed: ${response.message}");
    setState(() => isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar("External Wallet Selected: ${response.walletName}");
  }

  Future<void> _saveBooking(String? paymentId) async {
    if (!_formKey.currentState!.validate()) {
      setState(() => isLoading = false);
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        CollectionReference bookings =
        FirebaseFirestore.instance.collection('bookings');

        DateTime serviceDateTime = DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          widget.time.hour,
          widget.time.minute,
        );

        Map<String, dynamic> bookingData = {
          'userId': user.uid,
          'providerId': providerId,
          'serviceId': serviceId,
          'serviceDate': Timestamp.fromDate(serviceDateTime),
          'bookingDate': FieldValue.serverTimestamp(),
          'location': {
            'latitude': _latitude,
            'longitude': _longitude,
            'local': addressController.text,
          },
          'paymentAmount': calculateTotalAmount(),
          'paymentMode': selectedPaymentMethod,
          'paymentStatus': paymentId != null ? 'Completed' : 'Pending',
          'paymentId': paymentId, // Store Razorpay payment ID
          'status': 'Pending',
        };

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Booking Confirmed!\n"
                    "Date: ${widget.date.toString().substring(0, 10)}\n"
                    "Time: ${widget.time.format(context)}\n"
                    "Service: ${widget.serviceData['name'] ?? 'Unknown'}",
              ),
              duration: Duration(seconds: 5),
            ),
        );
        await bookings.add(bookingData);

        // CollectionReference serviceDateCollection =
        // FirebaseFirestore.instance.collection('servicedate');

        // await serviceDateCollection.add({
        //   'userId': user.uid,
        //   'serviceId': serviceId,
        //   'providerId': providerId,
        //   'serviceDate': Timestamp.fromDate(widget.date),
        //   'serviceTime': Timestamp.fromDate(serviceDateTime),
        //   'createdAt': FieldValue.serverTimestamp(),
        // });

        _showSnackBar("Booking created successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error creating booking: $e");
    }
    setState(() => isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? selectedPaymentImage;

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _showPaymentMethodSelector(),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset(
                      selectedPaymentImage ?? 'android/assets/debit card.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedPaymentMethod,
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading:
              Image.asset('android/assets/debit card.png', width: 30, height: 30),
              title: Text('Debit Card'),
              trailing: selectedPaymentMethod == 'Debit Card'
                  ? Icon(Icons.check_circle, color: Color(0xFF060644))
                  : null,
              onTap: () {
                setState(() {
                  selectedPaymentMethod = 'Debit Card';
                  selectedPaymentImage = 'android/assets/debit card.png';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Image.asset('android/assets/Gpay.png', width: 30, height: 30),
              title: Text('UPI'),
              trailing: selectedPaymentMethod == 'UPI'
                  ? Icon(Icons.check_circle, color: Color(0xFF060644))
                  : null,
              onTap: () {
                setState(() {
                  selectedPaymentMethod = 'UPI';
                  selectedPaymentImage = 'android/assets/Gpay.png';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Image.asset('android/assets/cash-on-delivery.png',
                  width: 30, height: 30),
              title: Text('Cash on Delivery'),
              trailing: selectedPaymentMethod == 'Cash on Delivery'
                  ? Icon(Icons.check_circle, color: Color(0xFF060644))
                  : null,
              onTap: () {
                setState(() {
                  selectedPaymentMethod = 'Cash on Delivery';
                  selectedPaymentImage = 'android/assets/cash-on-delivery.png';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '₹${amount.round()}',
          style: style,
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          _buildPaymentRow('Item total', servicePrice),
          SizedBox(height: 16),
          _buildPaymentRow('Tax (11%)', calculateTaxAmount()),
          SizedBox(height: 16),
          _buildPaymentRow('Platform Fee (1%)', calculatePlatformFee()),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey.shade300),
          ),
          _buildPaymentRow('Total amount', calculateTotalAmount(), isBold: true),
          SizedBox(height: 16),
          _buildPaymentRow('Amount to pay', calculateTotalAmount(), isBold: true),
        ],
      ),
    );
  }

  // Check if address is filled to enable/disable button
  bool get _isAddressFilled => addressController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF060644),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: addressController,
                            label: 'Enter Address',
                            icon: Icons.location_on,
                            suffix: TextButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: Icon(Icons.my_location, color: Color(0xFF060644)),
                              label: Text(
                                '',
                                style: TextStyle(color: Color(0xFF060644)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildPaymentSummary(),
                    SizedBox(height: 20),
                    _buildPaymentMethodSelector(),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAddressFilled && !isLoading
                            ? () {
                          setState(() => isLoading = true);
                          if (selectedPaymentMethod == 'Cash on Delivery') {
                            _saveBooking(null); // No payment ID for COD
                          } else {
                            _openRazorpayCheckout(); // Open Razorpay for other methods
                          }
                        }
                            : null, // Button disabled if address is empty or loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAddressFilled && !isLoading
                              ? Color(0xFF060644) // Enabled color
                              : Colors.grey, // Disabled color
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Processing...',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        )
                            : Text(
                          'Request Booking',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF060644)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}