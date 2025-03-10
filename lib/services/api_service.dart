
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_company.dart';
import '../models/calculation.dart';

class ApiService {
  static const String _baseUrl = 'https://fuel-price-api.example.com'; // Replace with actual API when available
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
      // In a real app, make an actual API call
      // For now, we'll simulate one with generated data
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      final mockData = _generateMockPriceData();
      
      // Save to cache
      prefs.setString(_cachePricesKey, json.encode(mockData));
      prefs.setString(_cacheTimeKey, now.toIso8601String());
      
      return mockData;
    } catch (e) {
      print('Error fetching fuel prices: $e');
      return null;
    }
  }
  
  // Generate mock fuel price data with small random fluctuations
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
      final apiCompanyData = priceData['data'][company.type.toString().split('.').last.toLowerCase()];
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
      return '${cacheTime.day}/${cacheTime.month}/${cacheTime.year} ${cacheTime.hour}:${cacheTime.minute.toString().padLeft(2, '0')}';
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
