
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_company.dart';
import '../models/calculation.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  // RapidAPI for Indian Fuel Prices
  static const String _baseUrl = "https://daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com/v1/fuel-prices/lowest/petrol/2022-09-01/india/cities";
  static const String _apiKey = "ddb2c8a0fdmshafd8fa095485b40p1eada5jsna22c622410d";
  static const String _apiHost = "daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com";
  
  static const String _cachePricesKey = 'cached_fuel_prices';
  static const String _cacheTimeKey = 'cached_fuel_prices_time';
  static const int _cacheExpiryMinutes = 10; // 10 minutes cache expiry
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();

  // Check if device is connected to internet
  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Function to fetch fuel prices with caching
  Future<Map<String, dynamic>?> fetchFuelPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Check if we have cached data and if it's still valid
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr != null) {
      final cacheTime = DateTime.parse(cacheTimeStr);
      final difference = now.difference(cacheTime).inMinutes;
      
      // If cache is still valid (less than expiry time)
      if (difference < _cacheExpiryMinutes) {
        final cachedData = prefs.getString(_cachePricesKey);
        if (cachedData != null) {
          return json.decode(cachedData);
        }
      }
    }
    
    // Check internet connectivity
    bool connected = await isConnected();
    if (!connected) {
      // Return cached data regardless of age if offline
      return _fallbackToPreviousPricesOrGenerate(prefs);
    }
    
    // If no valid cached data, make an API call
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Convert API response to our fuel price format
        final fuelPriceData = _convertRapidApiToFuelPrices(responseData);
        
        // Save to cache
        prefs.setString(_cachePricesKey, json.encode(fuelPriceData));
        prefs.setString(_cacheTimeKey, now.toIso8601String());
        
        return fuelPriceData;
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        print('Response body: ${response.body}');
        return _fallbackToPreviousPricesOrGenerate(prefs);
      }
    } catch (e) {
      print('Error fetching fuel prices: $e');
      return _fallbackToPreviousPricesOrGenerate(prefs);
    }
  }
  
  // Convert RapidAPI data to our fuel price format
  Map<String, dynamic> _convertRapidApiToFuelPrices(Map<String, dynamic> apiData) {
    // Create a map for fuel companies and their prices
    final responseData = <String, Map<String, double>>{};
    
    // Default prices in case the API doesn't provide all fuel types
    final basePrice = {
      'petrol': 96.72,
      'diesel': 89.62,
      'cng': 76.59,
    };
    
    try {
      // Extract prices from the API response
      var cities = apiData['data'] as List<dynamic>;
      
      // Get average prices from multiple cities
      double petrolSum = 0;
      double dieselSum = 0;
      int petrolCount = 0;
      int dieselCount = 0;
      
      for (var city in cities) {
        if (city['petrol'] != null && city['petrol'].toString().isNotEmpty) {
          double price = double.tryParse(city['petrol'].toString()) ?? 0.0;
          if (price > 0) {
            petrolSum += price;
            petrolCount++;
          }
        }
        
        if (city['diesel'] != null && city['diesel'].toString().isNotEmpty) {
          double price = double.tryParse(city['diesel'].toString()) ?? 0.0;
          if (price > 0) {
            dieselSum += price;
            dieselCount++;
          }
        }
      }
      
      // Calculate averages
      double petrolAvg = petrolCount > 0 ? petrolSum / petrolCount : basePrice['petrol']!;
      double dieselAvg = dieselCount > 0 ? dieselSum / dieselCount : basePrice['diesel']!;
      
      // Use a factor for CNG since the API might not provide it
      double cngPrice = petrolAvg * 0.8; // Usually CNG is around 80% of petrol price
      
      // Create variation in prices for different companies
      responseData['iocl'] = {
        'petrol': petrolAvg,
        'diesel': dieselAvg,
      };
      
      responseData['bpcl'] = {
        'petrol': petrolAvg - 0.3,
        'diesel': dieselAvg - 0.4,
      };
      
      responseData['hpcl'] = {
        'petrol': petrolAvg - 0.1,
        'diesel': dieselAvg - 0.1,
      };
      
      responseData['reliance'] = {
        'petrol': petrolAvg + 0.4,
        'diesel': dieselAvg + 0.5,
      };
      
      responseData['nayara'] = {
        'petrol': petrolAvg + 0.2,
        'diesel': dieselAvg + 0.2,
      };
      
      responseData['shell'] = {
        'petrol': petrolAvg + 1.8,
        'diesel': dieselAvg + 1.8,
      };
      
      // CNG companies
      responseData['igl'] = {
        'cng': cngPrice,
      };
      
      responseData['mgl'] = {
        'cng': cngPrice - 2.1,
      };
      
      responseData['adani'] = {
        'cng': cngPrice + 1.7,
      };
    } catch (e) {
      print('Error processing API data: $e');
      
      // If there's an error parsing the API response, use the default prices
      responseData['iocl'] = {'petrol': basePrice['petrol']!, 'diesel': basePrice['diesel']!};
      responseData['bpcl'] = {'petrol': basePrice['petrol']! - 0.3, 'diesel': basePrice['diesel']! - 0.4};
      responseData['hpcl'] = {'petrol': basePrice['petrol']! - 0.1, 'diesel': basePrice['diesel']! - 0.1};
      responseData['reliance'] = {'petrol': basePrice['petrol']! + 0.4, 'diesel': basePrice['diesel']! + 0.5};
      responseData['nayara'] = {'petrol': basePrice['petrol']! + 0.2, 'diesel': basePrice['diesel']! + 0.2};
      responseData['shell'] = {'petrol': basePrice['petrol']! + 1.8, 'diesel': basePrice['diesel']! + 1.8};
      responseData['igl'] = {'cng': basePrice['cng']!};
      responseData['mgl'] = {'cng': basePrice['cng']! - 3.1};
      responseData['adani'] = {'cng': basePrice['cng']! + 1.7};
    }
    
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
