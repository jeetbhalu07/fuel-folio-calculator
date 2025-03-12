import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/calculation.dart';
import '../models/calculation_history_provider.dart';
import '../models/fuel_company.dart';
import '../services/api_service.dart';
import 'fuel_type_selector.dart';
import 'company_selector.dart';
import 'calculator_input.dart';
import 'calculator_result.dart';
import 'purchase_calculator.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> with SingleTickerProviderStateMixin {
  FuelType selectedFuelType = FuelType.petrol;
  late FuelCompany selectedCompany;
  late CalculationInput inputs;
  late CalculationResult result;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuccessMessage = false;
  int _selectedTabIndex = 0;
  List<FuelCompany> _companies = [];
  bool _isLoadingPrices = false;
  String _lastUpdateTime = '';
  bool _isOffline = false;
  final ApiService _apiService = ApiService();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _companies = getFuelCompanies();
    selectedCompany = getDefaultCompany(selectedFuelType);
    inputs = getDefaultValues(selectedFuelType);
    // Update fuel price based on selected company
    inputs.fuelPrice = getCompanyFuelPrice(selectedCompany, selectedFuelType);
    result = calculateFuelCost(inputs);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Check connectivity status initially
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
      
      // Always refresh prices on start, even if offline (will use cached data)
      _refreshPrices();
    });
    
    // Monitor connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _isOffline;
      final isNowOffline = result == ConnectivityResult.none;
      
      setState(() {
        _isOffline = isNowOffline;
      });
      
      // If we're coming back online, refresh prices
      if (wasOffline && !isNowOffline) {
        _refreshPrices();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void handleFuelTypeChange(FuelType type) {
    setState(() {
      selectedFuelType = type;
      selectedCompany = getDefaultCompany(type);
      inputs = getDefaultValues(type);
      // Update fuel price based on selected company
      inputs.fuelPrice = getCompanyFuelPrice(selectedCompany, selectedFuelType);
      result = calculateFuelCost(inputs);
    });
  }

  void handleCompanyChange(FuelCompany company) {
    setState(() {
      selectedCompany = company;
      // Update only the fuel price when company changes
      inputs.fuelPrice = getCompanyFuelPrice(company, selectedFuelType);
      result = calculateFuelCost(inputs);
    });
  }

  void handleInputChange(String field, double value) {
    setState(() {
      switch (field) {
        case 'fuelPrice':
          inputs.fuelPrice = value;
          break;
        case 'distance':
          inputs.distance = value;
          break;
        case 'mileage':
          inputs.mileage = value;
          break;
      }
      result = calculateFuelCost(inputs);
    });
  }

  void handleReset() {
    setState(() {
      inputs = getDefaultValues(selectedFuelType);
      // Update fuel price based on selected company
      inputs.fuelPrice = getCompanyFuelPrice(selectedCompany, selectedFuelType);
      result = calculateFuelCost(inputs);
    });
  }
  
  void saveCalculation() {
    final historyProvider = Provider.of<CalculationHistoryProvider>(
      context, 
      listen: false
    );
    
    historyProvider.addCalculation(selectedFuelType, inputs, result);
    
    setState(() {
      _showSuccessMessage = true;
    });
    
    // Hide success message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSuccessMessage = false;
        });
      }
    });
  }
  
  Future<void> _refreshPrices() async {
    // Show loading indicator even when offline
    setState(() {
      _isLoadingPrices = true;
    });
    
    try {
      final updatedCompanies = await _apiService.updateCompaniesWithApiPrices(_companies);
      final lastUpdateTime = await _apiService.getLastPriceUpdateTime();
      
      if (mounted) {
        setState(() {
          _companies = updatedCompanies;
          _lastUpdateTime = lastUpdateTime;
          
          // Update selected company with new prices
          for (var company in updatedCompanies) {
            if (company.type == selectedCompany.type) {
              selectedCompany = company;
              // Update fuel price
              inputs.fuelPrice = getCompanyFuelPrice(company, selectedFuelType);
              result = calculateFuelCost(inputs);
              break;
            }
          }
        });
        
        if (_isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using cached fuel prices while offline.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fuel prices updated successfully. Last update: $lastUpdateTime'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error refreshing prices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default fuel prices: ${e.toString().substring(0, min(50, e.toString().length))}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrices = false;
        });
      }
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          FuelTypeSelector(
            selectedFuelType: selectedFuelType,
            onChanged: handleFuelTypeChange,
          ),
          
          // Network status indicator
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Offline Mode - Using cached prices',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          
          // Last update time
          if (_lastUpdateTime.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Last update: $_lastUpdateTime',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ),
          
          // Refresh prices button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isLoadingPrices || _isOffline ? null : _refreshPrices,
              icon: _isLoadingPrices 
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 14),
              label: Text(_isLoadingPrices 
                  ? 'Updating...' 
                  : _isOffline 
                      ? 'Offline' 
                      : 'Refresh Prices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Company Selector
          CompanySelector(
            selectedFuelType: selectedFuelType,
            selectedCompany: selectedCompany,
            onChanged: handleCompanyChange,
            companies: _companies,
            isRefreshing: _isLoadingPrices,
          ),
          
          const SizedBox(height: 16),
          
          // Tab Selector
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[850]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calculate,
                            size: 16,
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trip Calculator',
                            style: TextStyle(
                              color: _selectedTabIndex == 0
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Purchase',
                            style: TextStyle(
                              color: _selectedTabIndex == 1
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          if (_selectedTabIndex == 0) ...[
            // Trip Calculator
            Container(
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
                children: [
                  CalculatorInput(
                    id: 'fuel-price',
                    label: 'Fuel Price',
                    value: inputs.fuelPrice,
                    onChanged: (value) => handleInputChange('fuelPrice', value),
                    unit: '₹ per ${getFuelUnit(selectedFuelType)}',
                    placeholder: 'Enter fuel price',
                  ),
                  
                  CalculatorInput(
                    id: 'distance',
                    label: 'Distance',
                    value: inputs.distance,
                    onChanged: (value) => handleInputChange('distance', value),
                    unit: 'km',
                    placeholder: 'Enter distance',
                  ),
                  
                  CalculatorInput(
                    id: 'mileage',
                    label: 'Vehicle Mileage',
                    value: inputs.mileage,
                    onChanged: (value) => handleInputChange('mileage', value),
                    unit: 'km per ${getFuelUnit(selectedFuelType)}',
                    placeholder: 'Enter mileage',
                  ),
                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: handleReset,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode 
                                ? Colors.grey[800] 
                                : Colors.grey[200],
                            foregroundColor: isDarkMode 
                                ? Colors.white
                                : Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: saveCalculation,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Success message
                  if (_showSuccessMessage)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Calculation saved successfully',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results Card
            CalculatorResult(
              result: result,
              fuelUnit: getFuelUnit(selectedFuelType),
            ),
          ],
          
          // Purchase Calculator Tab
          if (_selectedTabIndex == 1)
            PurchaseCalculator(
              selectedFuelType: selectedFuelType,
              fuelPrice: inputs.fuelPrice,
            ),
        ],
      ),
    );
  }
}
