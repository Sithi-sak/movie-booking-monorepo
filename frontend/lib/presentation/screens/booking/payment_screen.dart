import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie_booking_app/core/theme/app_theme.dart';
import 'package:movie_booking_app/services/booking_service.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final String bookingReference;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.bookingReference,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _successAnimation;

  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String? _errorMessage;
  String? _paymentReference;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Pre-fill with mock card data for testing
    _cardNumberController.text = '4111 1111 1111 1111';
    _cardHolderController.text = 'JOHN DOE';
    _expiryController.text = '12/25';
    _cvvController.text = '123';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await BookingService.processPayment(
        bookingId: widget.bookingId,
        amount: widget.totalAmount,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryDate: _expiryController.text,
        cvv: _cvvController.text,
      );

      setState(() {
        _paymentSuccess = true;
        _paymentReference = result['payment']?['paymentReference'] as String?;
        _isProcessing = false;
      });

      _successController.forward();

      // Wait for animation, then navigate back to home
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.backgroundDark.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: _paymentSuccess ? _buildSuccessView() : _buildPaymentForm(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: ScaleTransition(
        scale: _successAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Reference: ${widget.bookingReference}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            if (_paymentReference != null) ...[
              const SizedBox(height: 8),
              Text(
                'Payment ID: $_paymentReference',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
            ),
            const SizedBox(height: 16),
            Text(
              'Redirecting to home...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Booking: ${widget.bookingReference}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is a mock payment. Any card details will work!',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card Number
                    Text(
                      'Card Number',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '1234 5678 9012 3456',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryRed),
                        ),
                        prefixIcon: Icon(Icons.credit_card, color: AppTheme.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter card number';
                        }
                        if (value.replaceAll(' ', '').length < 13) {
                          return 'Card number must be at least 13 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Card Holder Name
                    Text(
                      'Card Holder Name',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cardHolderController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'JOHN DOE',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryRed),
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter card holder name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Expiry and CVV
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _expiryController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'MM/YY',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                                  filled: true,
                                  fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.borderDark),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.borderDark),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryRed),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 5) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CVV',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: InputDecoration(
                                  hintText: '123',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                                  filled: true,
                                  fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.borderDark),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.borderDark),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryRed),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 3) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade200),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryRed.withValues(alpha: 0.2),
                            AppTheme.primaryRed.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${widget.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Pay \$${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secure payment notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Secure mock payment',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card number formatter: 1234 5678 9012 3456
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Expiry date formatter: MM/YY
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length <= 2) {
      return newValue;
    }

    final month = text.substring(0, 2);
    final year = text.substring(2);

    return TextEditingValue(
      text: '$month/$year',
      selection: TextSelection.collapsed(offset: '$month/$year'.length),
    );
  }
}
