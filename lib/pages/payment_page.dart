import 'package:flutter/material.dart';
import 'package:skillpe/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showSuccessState() async {
    await _animationController.forward();
    setState(() => _showSuccess = true);
    await _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              themeProvider.isDarkMode
                  ? 'assets/images/payment-bg.png'
                  : 'assets/images/payment-bg.png',
            ),
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _showSuccess ? 1 : _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child:
                          _showSuccess
                              ? _buildSuccessState()
                              : _buildPaymentState(themeProvider),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final bool isAndroid = UniversalPlatform.isAndroid;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(50),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!, width: 1),
              borderRadius: BorderRadius.circular(24),
              color: const Color(
                0xFF1A1A1A,
              ).withValues(alpha: isAndroid ? 0.8 : 0.22), // Darker for Android
            ),
            child:
                isAndroid
                    ? Column(
                      children: [
                        Image.asset(
                          'assets/images/payment-done.png',
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Yay!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Payment successful',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "you're good to go!",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ],
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/payment-done.png',
                              height: 100,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Yay!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Payment successful',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "you're good to go!",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),

          const Spacer(),
          ElevatedButton(
            onPressed:
                () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Continue learning',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPaymentState(ThemeProvider themeProvider) {
    final bool isAndroid = UniversalPlatform.isAndroid;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF1A1A1A).withValues(
                      alpha: isAndroid ? 0.8 : 0.22,
                    ), // Darker for Android
                  ),
                  padding: const EdgeInsets.all(24),
                  child:
                      isAndroid
                          ? Column(
                            children: [
                              const SizedBox(height: 40),
                              const Text(
                                'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              _buildPriceTag(),
                              const SizedBox(height: 16),
                              const Text(
                                'Unlocks everything',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Faster learning, faster earning',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              const Divider(
                                color: Color(0xFF4E4E4E),
                                height: 0.738,
                              ),
                              const SizedBox(height: 48),
                              _buildFeaturesList(),
                              const Spacer(),
                              _buildSubscribeButton(),
                            ],
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 5.0,
                                sigmaY: 5.0,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  const Text(
                                    'Subscribe Now',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  _buildPriceTag(),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Unlocks everything',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Faster learning, faster earning',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 48),
                                  const Divider(
                                    color: Color(0xFF4E4E4E),
                                    height: 0.738,
                                  ),
                                  const SizedBox(height: 48),
                                  _buildFeaturesList(),
                                  const Spacer(),
                                  _buildSubscribeButton(),
                                ],
                              ),
                            ),
                          ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.grey[800]!, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Image.asset('assets/images/price.png', width: 268, height: 99);
  }

  Widget _buildFeaturesList() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(
        6,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.yellow[300], size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Mentor',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Show loading indicator
          _showLoadingDialog();

          // Get auth token
          final prefs = await SharedPreferences.getInstance();
          final authToken = prefs.getString('auth_token');

          if (authToken == null) {
            Navigator.of(context).pop(); // Close loading dialog
            _showErrorSnackBar('Authentication error. Please login again.');
            return;
          }

          // Set expiry date to 1 year from now
          final expiryDate =
              DateTime.now()
                  .add(const Duration(days: 365))
                  .toUtc()
                  .toIso8601String();

          // Call the subscription API
          final response = await http.patch(
            Uri.parse('${Env.apiUrl}/users/subscription'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({
              'subscriptionStatus': 'paid',
              'subscriptionExpiry': expiryDate,
            }),
          );

          Navigator.of(context).pop(); // Close loading dialog

          if (response.statusCode == 200) {
            // API call was successful, show success state
            await _showSuccessState();

            // Navigate to home page
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            // API call failed
            final responseBody = json.decode(response.body);
            _showErrorSnackBar(
              responseBody['message'] ?? 'Subscription update failed',
            );
          }
        } catch (e) {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorSnackBar('Network error: ${e.toString()}');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text(
        'Pay and Subscribe now',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing payment...'),
              ],
            ),
          ),
    );
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
