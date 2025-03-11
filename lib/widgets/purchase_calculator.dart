
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calculation.dart';
import '../services/api_service.dart';
import 'calculator_input.dart';

class PurchaseHistory {
  final String id;
  final FuelType fuelType;
  final double amountPaid;
  final double fuelQuantity;
  final double billQuantity;
  final bool verified;
  final DateTime date;

  PurchaseHistory({
    required this.id,
    required this.fuelType,
    required this.amountPaid,
    required this.fuelQuantity,
    required this.billQuantity,
    required this.verified,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fuelType': fuelType.toString().split('.').last,
    'amountPaid': amountPaid,
    'fuelQuantity': fuelQuantity,
    'billQuantity': billQuantity,
    'verified': verified,
    'date': date.toIso8601String(),
  };

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    FuelType getFuelType(String type) {
      switch (type) {
        case 'petrol': return FuelType.petrol;
        case 'diesel': return FuelType.diesel;
        case 'cng': return FuelType.cng;
        default: return FuelType.petrol;
      }
    }

    return PurchaseHistory(
      id: json['id'],
      fuelType: getFuelType(json['fuelType']),
      amountPaid: json['amountPaid'].toDouble(),
      fuelQuantity: json['fuelQuantity'].toDouble(),
      billQuantity: json['billQuantity'].toDouble(),
      verified: json['verified'],
      date: DateTime.parse(json['date']),
    );
  }
}

class PurchaseCalculator extends StatefulWidget {
  final FuelType selectedFuelType;
  final double fuelPrice;

  const PurchaseCalculator({
    Key? key,
    required this.selectedFuelType,
    required this.fuelPrice,
  }) : super(key: key);

  @override
  State<PurchaseCalculator> createState() => _PurchaseCalculatorState();
}

class _PurchaseCalculatorState extends State<PurchaseCalculator> {
  double amountPaid = 200.0;
  double fuelQuantity = 0.0;
  double billQuantity = 0.0;
  bool? verificationResult;
  bool _showVerificationMessage = false;
  List<PurchaseHistory> _purchaseHistory = [];
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _calculateFuelQuantity();
    _loadPurchaseHistory();
  }
  
  @override
  void didUpdateWidget(PurchaseCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuelPrice != widget.fuelPrice) {
      _calculateFuelQuantity();
    }
  }
  
  void _calculateFuelQuantity() {
    if (widget.fuelPrice > 0) {
      setState(() {
        fuelQuantity = double.parse((amountPaid / widget.fuelPrice).toStringAsFixed(2));
      });
    }
  }
  
  void _handleAmountChanged(double value) {
    setState(() {
      amountPaid = value;
      _calculateFuelQuantity();
    });
  }
  
  void _handleBillQuantityChanged(double value) {
    setState(() {
      billQuantity = value;
    });
  }
  
  void _verifyBill() {
    if (billQuantity <= 0) {
      _showSnackBar("Please enter the fuel quantity from your bill", Colors.red);
      return;
    }
    
    final expectedAmount = billQuantity * widget.fuelPrice;
    final expectedRounded = double.parse(expectedAmount.toStringAsFixed(2));
    final amountRounded = double.parse(amountPaid.toStringAsFixed(2));
    
    // Allow a small tolerance for rounding errors
    final isValid = (expectedRounded - amountRounded).abs() <= 0.05;
    
    setState(() {
      verificationResult = isValid;
      _showVerificationMessage = true;
    });
    
    _savePurchaseRecord(isValid);
    
    _showSnackBar(
      isValid 
          ? "Bill verification successful! The amount matches the fuel quantity."
          : "Bill verification failed! There's a discrepancy between the amount and fuel quantity.",
      isValid ? Colors.green : Colors.red
    );
    
    // Hide message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showVerificationMessage = false;
        });
      }
    });
  }
  
  Future<void> _loadPurchaseHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('purchaseHistory');
      
      if (historyJson != null) {
        final List<dynamic> decodedList = json.decode(historyJson);
        setState(() {
          _purchaseHistory = decodedList
              .map((item) => PurchaseHistory.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading purchase history: $e');
    }
  }
  
  Future<void> _savePurchaseRecord(bool isValid) async {
    try {
      final newRecord = PurchaseHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fuelType: widget.selectedFuelType,
        amountPaid: amountPaid,
        fuelQuantity: fuelQuantity,
        billQuantity: billQuantity,
        verified: isValid,
        date: DateTime.now(),
      );
      
      _purchaseHistory.add(newRecord);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('purchaseHistory', 
        json.encode(_purchaseHistory.map((record) => record.toJson()).toList())
      );
    } catch (e) {
      print('Error saving purchase record: $e');
    }
  }
  
  Future<void> _clearPurchaseHistory() async {
    try {
      setState(() {
        _purchaseHistory.clear();
      });
      
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('purchaseHistory');
      
      _showSnackBar('Purchase history cleared', Colors.blue);
    } catch (e) {
      print('Error clearing purchase history: $e');
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fuelUnit = getFuelUnit(widget.selectedFuelType);
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey[900]!.withOpacity(0.7) 
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Purchase Calculator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300],
          ),
          
          CalculatorInput(
            id: 'amount-paid',
            label: 'Amount Paid',
            value: amountPaid,
            onChanged: _handleAmountChanged,
            unit: '₹',
            placeholder: 'Enter amount paid',
          ),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fuel Quantity:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Text(
                  '$fuelQuantity $fuelUnit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 32),
          
          Text(
            'Verify Your Bill',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          CalculatorInput(
            id: 'bill-quantity',
            label: 'Quantity on Bill',
            value: billQuantity,
            onChanged: _handleBillQuantityChanged,
            unit: fuelUnit,
            placeholder: 'Enter quantity from bill',
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verifyBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Verify Bill'),
            ),
          ),
            
          // Verification result
          if (_showVerificationMessage && verificationResult != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: verificationResult! 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: verificationResult!
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    verificationResult! ? Icons.check_circle : Icons.warning,
                    color: verificationResult! ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      verificationResult!
                          ? 'Bill is correct! The fuel quantity matches the amount paid.'
                          : 'Bill may be incorrect! The fuel quantity doesn\'t match the amount paid.',
                      style: TextStyle(
                        color: verificationResult! ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          if (_purchaseHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Purchase History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: _clearPurchaseHistory,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _purchaseHistory.length > 3 ? 3 : _purchaseHistory.length,
                itemBuilder: (context, index) {
                  final reversedIndex = _purchaseHistory.length - 1 - index;
                  final item = _purchaseHistory[reversedIndex];
                  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.grey[850]!.withOpacity(0.7)
                          : Colors.grey[100]!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.verified 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormatter.format(item.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.verified 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.verified ? 'Verified' : 'Failed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: item.verified ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount Paid',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${item.amountPaid.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${item.fuelQuantity.toStringAsFixed(2)} ${getFuelUnit(item.fuelType)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
