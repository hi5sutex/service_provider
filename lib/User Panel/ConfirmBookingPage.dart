import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:service_provider/notification_service.dart';
import 'package:service_provider/secrets.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

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
  double get servicePrice => (widget.serviceData['price'] as num?)?.toDouble() ?? 0.0;
  String get providerId => widget.serviceData['createdBy'] ?? '';
  String get serviceId => widget.serviceId;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    addressController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    addressController.dispose();
    super.dispose();
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
      style: TextStyle(
        fontSize: 16,
        color: UserTheme.primaryTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: UserTheme.secondaryTextColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: UserTheme.primaryColor,
          size: 22,
        ),
        suffixIcon: suffix,
        filled: filled,
        fillColor: filled ? UserTheme.dividerColor.withOpacity(0.5) : Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: UserTheme.dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: UserTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 12,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(UserTheme.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                "Current Location Fetching...",
                style: TextStyle(
                  color: UserTheme.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.pop(context); // Close dialog
            _showSnackBar("Location permission denied");
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.pop(context); // Close dialog
          _showSnackBar("Location permission permanently denied");
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;

      String address = await _getHumanReadableAddress(_latitude!, _longitude!);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        setState(() {
          addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showSnackBar("Error fetching location: $e");
      }
    }
  }

  Future<String> _getHumanReadableAddress(double lat, double lon) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");
    try {
      final response = await http.get(url, headers: {
        "User-Agent": "ServiceProviderApp/1.0"
      });
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
      'key': 'rzp_test_8MwbMjCkPlKzhh',
      'amount': (calculateTotalAmount() * 100).toInt(),
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
    _showSnackBar("Payment Successful!");
    _saveBooking(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackBar("Payment Failed: ${response.message}");
    setState(() => isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar("External Wallet Selected: ${response.walletName}");
  }

  Future<String> _getAccessToken() async {
    final serviceAccount = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await clientViaServiceAccount(
      serviceAccount,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  Future<void> _saveBooking(String? paymentId) async {
    if (!_formKey.currentState!.validate()) {
      setState(() => isLoading = false);
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        CollectionReference bookings = FirebaseFirestore.instance.collection('bookings');

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
          'serviceName': widget.serviceData['name'],
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
          'paymentId': paymentId,
          'status': 'Pending',
          'isNotificationCleared': false,
          'clearedAt': null,
        };

        DocumentReference bookingRef = await bookings.add(bookingData);
        String bookingId = bookingRef.id;

        CollectionReference earnings = FirebaseFirestore.instance.collection('earnings');
        CollectionReference earningsRecords = earnings.doc(providerId).collection('records');
        await earningsRecords.doc(bookingId).set({
          'paymentId': paymentId ?? 'COD',
          'serviceAmount': servicePrice,
          'taxAmount': calculateTaxAmount(),
          'platformFee': calculatePlatformFee(),
          'paymentAmount': calculateTotalAmount(),
          'earningStatus': 'Pending',
          'paymentAt': FieldValue.serverTimestamp(),
        });

        await NotificationService().sendNotification(
          toUserId: providerId,
          toRole: 'provider',
          title: 'New Booking Request',
          body: 'A new booking for ${widget.serviceData['name']} has been requested!',
          type: 'booking',
          data: {'bookingId': bookingId},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Booking confirmed successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          Future.delayed(Duration(milliseconds: 1500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      _showSnackBar("Error creating booking: $e");
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: UserTheme.primaryColor.withOpacity(0.9),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  String? selectedPaymentImage;

  Widget _buildBookingSummary() {
    String formattedDate = "${widget.date.day}/${widget.date.month}/${widget.date.year}";
    String formattedTime = widget.time.format(context);

    return Container(
      decoration: BoxDecoration(
        color: UserTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: UserTheme.shadowColor.withOpacity(0.1),
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
            'Booking Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: UserTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UserTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: UserTheme.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: UserTheme.secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$formattedDate - $formattedTime',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UserTheme.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UserTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.handyman_rounded,
                  color: UserTheme.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service',
                      style: TextStyle(
                        fontSize: 14,
                        color: UserTheme.secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.serviceData['name'] ?? 'Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: UserTheme.primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: UserTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: UserTheme.shadowColor.withOpacity(0.1),
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
              color: UserTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _showPaymentMethodSelector(),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: UserTheme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset(
                      selectedPaymentImage ?? 'android/assets/debit card.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      selectedPaymentMethod,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: UserTheme.primaryTextColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: UserTheme.primaryColor,
                    size: 24,
                  ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: UserTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: UserTheme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: UserTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            _buildPaymentOption(
              title: 'Debit Card',
              imagePath: 'android/assets/debit card.png',
              isSelected: selectedPaymentMethod == 'Debit Card',
              onTap: () {
                setState(() {
                  selectedPaymentMethod = 'Debit Card';
                  selectedPaymentImage = 'android/assets/debit card.png';
                });
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, thickness: 1, color: UserTheme.dividerColor.withOpacity(0.3)),
            _buildPaymentOption(
              title: 'UPI',
              imagePath: 'android/assets/Gpay.png',
              isSelected: selectedPaymentMethod == 'UPI',
              onTap: () {
                setState(() {
                  selectedPaymentMethod = 'UPI';
                  selectedPaymentImage = 'android/assets/Gpay.png';
                });
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, thickness: 1, color: UserTheme.dividerColor.withOpacity(0.3)),
            _buildPaymentOption(
              title: 'Cash on Delivery',
              imagePath: 'android/assets/cash-on-delivery.png',
              isSelected: selectedPaymentMethod == 'Cash on Delivery',
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

  Widget _buildPaymentOption({
    required String title,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 36,
                height: 36,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: UserTheme.primaryTextColor,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: UserTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: isBold ? 18 : 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: isBold ? UserTheme.primaryColor : UserTheme.primaryTextColor,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      decoration: BoxDecoration(
        color: UserTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: UserTheme.shadowColor.withOpacity(0.1),
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
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: UserTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          _buildPaymentRow('Service Price', servicePrice),
          _buildPaymentRow('Tax (11%)', calculateTaxAmount()),
          _buildPaymentRow('Platform Fee (1%)', calculatePlatformFee()),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: UserTheme.dividerColor),
          ),
          _buildPaymentRow('Total Amount', calculateTotalAmount(), isBold: true),
        ],
      ),
    );
  }

  bool get _isAddressFilled => addressController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: UserTheme.primaryColor,
        elevation: 0,
        title: Text(
          'Confirm Booking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingSummary(),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: UserTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: UserTheme.shadowColor.withOpacity(0.1),
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
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UserTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: addressController,
                        label: 'Enter service location',
                        icon: Icons.location_on_rounded,
                        suffix: InkWell(
                          onTap: _getCurrentLocation,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: UserTheme.primaryColor,
                              size: 24,
                            ),
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
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          onPressed: _isAddressFilled && !isLoading
              ? () {
            setState(() => isLoading = true);
            if (selectedPaymentMethod == 'Cash on Delivery') {
              _saveBooking(null);
            } else {
              _openRazorpayCheckout();
            }
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAddressFilled
                ? UserTheme.primaryColor
                : UserTheme.disabledButtonColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            'Confirm Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isAddressFilled
                  ? Colors.white
                  : UserTheme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}