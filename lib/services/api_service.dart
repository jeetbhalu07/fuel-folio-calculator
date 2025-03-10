
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_company.dart';
import '../models/calculation.dart';
import 'package:intl/intl.dart';

class ApiService {
  // We'll use the Free Currency API as it's publicly accessible without auth for demo
  // In a real-world app, you would use a dedicated fuel price API
  static const String _baseUrl = 'https://api.currencyapi.com/v3/latest?apikey=cur_live_LjjgqiDNFKUr5Z3iEpHFcSPvEgjlhjuOQ9kcyDiY';
  static const String _cachePricesKey = 'cached_fuel_prices';
  static const String _cacheTimeKey = 'cached_fuel_prices_time';
  static const int _cacheExpiryMinutes = 10;
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Function to fetch fuel prices with caching
  Future<Map<String, dynamic>?> fetchFuelPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Check if we have cached data and if it's still valid
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr != null) {
      final cacheTime = DateTime.parse(cacheTimeStr);
      final difference = now.difference(cacheTime).inMinutes;
      
      // If cache is still valid (less than 10 minutes old)
      if (difference < _cacheExpiryMinutes) {
        final cachedData = prefs.getString(_cachePricesKey);
        if (cachedData != null) {
          return json.decode(cachedData);
        }
      }
    }
    
    // If no valid cached data, make an API call
    try {
      // We'll use the currency API to generate some realistic fluctuating values
      // In a real app, you'd connect to a proper fuel price API
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final currencyData = json.decode(response.body);
        
        // Convert currency data to fuel price format
        final fuelPriceData = _convertCurrencyToFuelPrices(currencyData);
        
        // Save to cache
        prefs.setString(_cachePricesKey, json.encode(fuelPriceData));
        prefs.setString(_cacheTimeKey, now.toIso8601String());
        
        return fuelPriceData;
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        return _fallbackToPreviousPricesOrGenerate(prefs);
      }
    } catch (e) {
      print('Error fetching fuel prices: $e');
      return _fallbackToPreviousPricesOrGenerate(prefs);
    }
  }
  
  // Convert currency API data to our fuel price format
  Map<String, dynamic> _convertCurrencyToFuelPrices(Map<String, dynamic> currencyData) {
    // Base prices for different fuel types
    final basePrices = {
      'petrol': 96.72,
      'diesel': 89.62,
      'cng': 76.59,
    };
    
    // Use currency rates to create realistic price variations
    final rates = currencyData['data'] ?? {};
    
    // Companies with their associated currency for variation
    final companyVariations = {
      'iocl': {'currency': 'INR', 'petrol': 0, 'diesel': 0},
      'bpcl': {'currency': 'USD', 'petrol': -0.3, 'diesel': -0.4},
      'hpcl': {'currency': 'EUR', 'petrol': -0.1, 'diesel': -0.1},
      'reliance': {'currency': 'GBP', 'petrol': 0.4, 'diesel': 0.5},
      'nayara': {'currency': 'JPY', 'petrol': 0.2, 'diesel': 0.2},
      'shell': {'currency': 'AUD', 'petrol': 1.8, 'diesel': 1.8},
      'igl': {'currency': 'CAD', 'cng': 0},
      'mgl': {'currency': 'CHF', 'cng': -3.1},
      'adani': {'currency': 'CNY', 'cng': 1.7},
    };
    
    // Generate response data
    final responseData = <String, Map<String, double>>{};
    
    // Fill in the data for each company
    companyVariations.forEach((company, config) {
      responseData[company] = {};
      
      final currencyCode = config['currency'] as String;
      final currencyValue = rates[currencyCode]?['value'] ?? 1.0;
      
      // Use currency fluctuations to influence fuel prices
      config.forEach((fuelType, variation) {
        if (fuelType != 'currency' && basePrices.containsKey(fuelType)) {
          final basePrice = basePrices[fuelType]!;
          // Use small percentage of currency variation + base variation
          final currencyFactor = ((currencyValue - 1) * 0.05);
          final variationFactor = 1 + ((variation as double) / 100) + currencyFactor;
          responseData[company]![fuelType] = double.parse((basePrice * variationFactor).toStringAsFixed(2));
        }
      });
    });
    
    return {
      'success': true,
      'data': responseData,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  // Fallback to previously cached prices or generate mock data if no cache exists
  Future<Map<String, dynamic>> _fallbackToPreviousPricesOrGenerate(SharedPreferences prefs) async {
    // Try to get previous cached data regardless of age
    final cachedData = prefs.getString(_cachePricesKey);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    
    // If no cache at all, generate mock data
    return _generateMockPriceData();
  }
  
  // Generate mock fuel price data with small random fluctuations (fallback method)
  Map<String, dynamic> _generateMockPriceData() {
    // Base prices for different fuel types
    final basePrices = {
      'petrol': 96.72,
      'diesel': 89.62,
      'cng': 76.59,
    };
    
    // Companies with their price variations (percentage difference from base)
    final companyVariations = {
      'iocl': {'petrol': 0, 'diesel': 0},
      'bpcl': {'petrol': -0.3, 'diesel': -0.4},
      'hpcl': {'petrol': -0.1, 'diesel': -0.1},
      'reliance': {'petrol': 0.4, 'diesel': 0.5},
      'nayara': {'petrol': 0.2, 'diesel': 0.2},
      'shell': {'petrol': 1.8, 'diesel': 1.8},
      'igl': {'cng': 0},
      'mgl': {'cng': -3.1},
      'adani': {'cng': 1.7},
    };
    
    // Add random daily fluctuation (-0.5% to +0.5%)
    double fluctuation() => (DateTime.now().millisecondsSinceEpoch % 100 - 50) / 10000;
    
    // Generate response data
    final responseData = <String, Map<String, double>>{};
    
    // Fill in the data for each company
    companyVariations.forEach((company, fuels) {
      responseData[company] = {};
      
      fuels.forEach((fuelType, variation) {
        final basePrice = basePrices[fuelType]!;
        final variationFactor = 1 + (variation / 100) + fluctuation();
        responseData[company]![fuelType] = double.parse((basePrice * variationFactor).toStringAsFixed(2));
      });
    });
    
    return {
      'success': true,
      'data': responseData,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  // Update fuel companies with latest prices from API
  Future<List<FuelCompany>> updateCompaniesWithApiPrices(List<FuelCompany> companies) async {
    final priceData = await fetchFuelPrices();
    
    if (priceData == null || priceData['success'] != true) {
      return companies;
    }
    
    // Create a copy of companies to update
    final updatedCompanies = List<FuelCompany>.from(companies);
    
    // Update each company with prices from API
    for (var i = 0; i < updatedCompanies.length; i++) {
      final company = updatedCompanies[i];
      final companyType = company.type.toString().split('.').last.toLowerCase();
      final apiCompanyData = priceData['data'][companyType];
      
      if (apiCompanyData == null) continue;
      
      // Update each fuel price that exists in the API response
      final updatedPrices = Map<String, double>.from(company.fuelPrices);
      
      apiCompanyData.forEach((String fuelType, dynamic price) {
        if (updatedPrices.containsKey(fuelType)) {
          updatedPrices[fuelType] = price.toDouble();
        }
      });
      
      // Create a new company with updated prices
      updatedCompanies[i] = FuelCompany(
        type: company.type,
        name: company.name,
        shortName: company.shortName,
        icon: company.icon,
        fuelPrices: updatedPrices,
        supportsCNG: company.supportsCNG,
      );
    }
    
    return updatedCompanies;
  }
  
  // Get the last update time for fuel prices
  Future<String> getLastPriceUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    
    if (cacheTimeStr == null) return 'Not available';
    
    try {
      final cacheTime = DateTime.parse(cacheTimeStr);
      // Format the date nicely
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      return dateFormat.format(cacheTime);
    } catch (e) {
      return 'Unknown';
    }
  }
  
  // Set up a timer to periodically refresh fuel prices
  Timer startPricePolling(Function(Map<String, dynamic>) callback) {
    // Initial fetch
    fetchFuelPrices().then((prices) {
      if (prices != null) callback(prices);
    });
    
    // Poll every 10 minutes
    return Timer.periodic(Duration(minutes: _cacheExpiryMinutes), (_) async {
      final prices = await fetchFuelPrices();
      if (prices != null) callback(prices);
    });
  }
}
