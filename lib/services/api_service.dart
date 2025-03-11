import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_company.dart';
import '../models/calculation.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static const String _baseUrl = "https://daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com/v1/fuel-prices/india/all";
  static const String _apiKey = "ddb2c8a0fdmshafd8fa095485b40p1eada5jsna22c622410d3";
  static const String _apiHost = "daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com";
  
  static const String _cachePricesKey = 'cached_fuel_prices';
  static const String _cacheTimeKey = 'cached_fuel_prices_time';
  static const int _cacheExpiryMinutes = 30; // 30 minutes cache expiry
  
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();

  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  Future<Map<String, dynamic>?> fetchFuelPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Check cache validity
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr != null) {
      final cacheTime = DateTime.parse(cacheTimeStr);
      final difference = now.difference(cacheTime).inMinutes;
      
      if (difference < _cacheExpiryMinutes) {
        final cachedData = prefs.getString(_cachePricesKey);
        if (cachedData != null) {
          print('Using cached fuel prices');
          return json.decode(cachedData);
        }
      }
    }
    
    // Check connectivity
    bool connected = await isConnected();
    if (!connected) {
      print('No internet connection, using fallback prices');
      return _fallbackToPreviousPricesOrGenerate(prefs);
    }
    
    try {
      print('Fetching fuel prices from API: $_baseUrl');
      
      // Make the API request with proper headers
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      );
      
      print('API Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('API Response: ${response.body.substring(0, 100)}...');
        final responseData = json.decode(response.body);
        
        // Convert the API response to our expected format
        final fuelPriceData = _convertRapidApiToFuelPrices(responseData);
        
        // Cache the data
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
  
  Map<String, dynamic> _convertRapidApiToFuelPrices(Map<String, dynamic> apiData) {
    final responseData = <String, Map<String, double>>{};
    
    try {
      print('Converting API data: ${apiData.keys}');
      
      // Extract the required data from the API response
      // The structure might be different, so we need to check the actual response
      if (apiData.containsKey('data') && apiData['data'] is Map) {
        final data = apiData['data'] as Map<String, dynamic>;
        
        // Get base prices for different fuels
        double petrolPrice = 0.0;
        double dieselPrice = 0.0;
        double cngPrice = 0.0;
        
        // Try to extract prices from the response structure
        if (data.containsKey('petrol')) {
          petrolPrice = _extractPriceFromData(data['petrol']);
        } else if (data.containsKey('delhi') && data['delhi'] is Map) {
          final delhi = data['delhi'] as Map<String, dynamic>;
          if (delhi.containsKey('petrol')) {
            petrolPrice = _extractPriceFromData(delhi['petrol']);
          }
        }
        
        if (data.containsKey('diesel')) {
          dieselPrice = _extractPriceFromData(data['diesel']);
        } else if (data.containsKey('delhi') && data['delhi'] is Map) {
          final delhi = data['delhi'] as Map<String, dynamic>;
          if (delhi.containsKey('diesel')) {
            dieselPrice = _extractPriceFromData(delhi['diesel']);
          }
        }
        
        if (data.containsKey('cng')) {
          cngPrice = _extractPriceFromData(data['cng']);
        } else if (data.containsKey('delhi') && data['delhi'] is Map) {
          final delhi = data['delhi'] as Map<String, dynamic>;
          if (delhi.containsKey('cng')) {
            cngPrice = _extractPriceFromData(delhi['cng']);
          }
        }
        
        print('Extracted prices: Petrol: $petrolPrice, Diesel: $dieselPrice, CNG: $cngPrice');
        
        // If we couldn't extract prices, use default values
        if (petrolPrice <= 0) petrolPrice = 96.72;
        if (dieselPrice <= 0) dieselPrice = 89.62;
        if (cngPrice <= 0) cngPrice = 76.59;
        
        // Set up company prices with variations
        responseData['iocl'] = {
          'petrol': petrolPrice,
          'diesel': dieselPrice,
        };
        
        responseData['bpcl'] = {
          'petrol': petrolPrice - 0.3,
          'diesel': dieselPrice - 0.4,
        };
        
        responseData['hpcl'] = {
          'petrol': petrolPrice - 0.1,
          'diesel': dieselPrice - 0.1,
        };
        
        responseData['reliance'] = {
          'petrol': petrolPrice + 0.4,
          'diesel': dieselPrice + 0.5,
        };
        
        responseData['nayara'] = {
          'petrol': petrolPrice + 0.2,
          'diesel': dieselPrice + 0.2,
        };
        
        responseData['shell'] = {
          'petrol': petrolPrice + 1.8,
          'diesel': dieselPrice + 1.8,
        };
        
        // Add CNG prices for applicable companies
        responseData['igl'] = {'cng': cngPrice};
        responseData['mgl'] = {'cng': cngPrice - 3.1};
        responseData['adani'] = {'cng': cngPrice + 1.7};
      } else {
        print('API data does not contain expected structure');
        return _generateMockPriceData()['data'] as Map<String, dynamic>;
      }
      
    } catch (e) {
      print('Error processing API data: $e');
      return _generateMockPriceData()['data'] as Map<String, dynamic>;
    }
    
    return {
      'success': true,
      'data': responseData,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  double _extractPriceFromData(dynamic priceData) {
    try {
      if (priceData is num) {
        return priceData.toDouble();
      } else if (priceData is String) {
        return double.tryParse(priceData.replaceAll('₹', '').trim()) ?? 0.0;
      } else if (priceData is Map && priceData.containsKey('price')) {
        final price = priceData['price'];
        if (price is num) {
          return price.toDouble();
        } else if (price is String) {
          return double.tryParse(price.replaceAll('₹', '').trim()) ?? 0.0;
        }
      }
    } catch (e) {
      print('Error extracting price from data: $e');
    }
    return 0.0;
  }
  
  Future<Map<String, dynamic>> _fallbackToPreviousPricesOrGenerate(SharedPreferences prefs) async {
    final cachedData = prefs.getString(_cachePricesKey);
    if (cachedData != null) {
      print('Using previously cached fuel prices');
      return json.decode(cachedData);
    }
    
    print('Generating mock fuel price data');
    return _generateMockPriceData();
  }
  
  Map<String, dynamic> _generateMockPriceData() {
    final basePrices = {
      'petrol': 96.72,
      'diesel': 89.62,
      'cng': 76.59,
    };
    
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
    
    double fluctuation() => (DateTime.now().millisecondsSinceEpoch % 100 - 50) / 10000;
    
    final responseData = <String, Map<String, double>>{};
    
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
  
  Future<List<FuelCompany>> updateCompaniesWithApiPrices(List<FuelCompany> companies) async {
    final priceData = await fetchFuelPrices();
    
    if (priceData == null || priceData['success'] != true) {
      return companies;
    }
    
    final updatedCompanies = List<FuelCompany>.from(companies);
    
    for (var i = 0; i < updatedCompanies.length; i++) {
      final company = updatedCompanies[i];
      final companyType = company.type.toString().split('.').last.toLowerCase();
      final apiCompanyData = priceData['data'][companyType];
      
      if (apiCompanyData == null) continue;
      
      final updatedPrices = Map<String, double>.from(company.fuelPrices);
      
      apiCompanyData.forEach((String fuelType, dynamic price) {
        if (updatedPrices.containsKey(fuelType)) {
          updatedPrices[fuelType] = price.toDouble();
        }
      });
      
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
  
  Future<String> getLastPriceUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    
    if (cacheTimeStr == null) return 'Not available';
    
    try {
      final cacheTime = DateTime.parse(cacheTimeStr);
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      return dateFormat.format(cacheTime);
    } catch (e) {
      return 'Unknown';
    }
  }
  
  Timer startPricePolling(Function(Map<String, dynamic>) callback) {
    fetchFuelPrices().then((prices) {
      if (prices != null) callback(prices);
    });
    
    return Timer.periodic(Duration(minutes: _cacheExpiryMinutes), (_) async {
      final prices = await fetchFuelPrices();
      if (prices != null) callback(prices);
    });
  }
}

