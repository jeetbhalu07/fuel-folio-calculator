import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_company.dart';
import '../models/calculation.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'scraping_service.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

class ApiService {
  // Updated to use Supabase URL
  static const String _supabaseUrl = "https://guxaidzxhsvinjvmgpnv.supabase.co";
  static const String _supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1eGFpZHp4aHN2aW5qdm1ncG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3MTU2NzcsImV4cCI6MjA1ODI5MTY3N30.5Pxyrwk6cdD1WMwPRCcO2awFl4xOlbKFX-1l3o6lIMQ";
  
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
      print('Fetching fuel prices from Supabase');
      
      // Fetch prices from Supabase using REST API
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/fuel_prices?select=company,fuel_type,price,updated_at'),
        headers: {
          'apikey': _supabaseKey,
          'Content-Type': 'application/json',
        },
      );
      
      print('Supabase Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> pricesData = json.decode(response.body);
        
        if (pricesData.isEmpty) {
          print('No fuel prices found in Supabase');
          return _fallbackToPreviousPricesOrGenerate(prefs);
        }
        
        // Format the data in the expected structure
        final Map<String, Map<String, double>> formattedData = {};
        String latestTimestamp = '';
        
        for (var item in pricesData) {
          final company = item['company'];
          final fuelType = item['fuel_type'];
          final price = double.parse(item['price'].toString());
          final updatedAt = item['updated_at'] ?? '';
          
          // Track latest timestamp
          if (latestTimestamp.isEmpty || updatedAt.compareTo(latestTimestamp) > 0) {
            latestTimestamp = updatedAt;
          }
          
          // Create company entry if it doesn't exist
          if (!formattedData.containsKey(company)) {
            formattedData[company] = {};
          }
          
          // Add fuel price
          formattedData[company]![fuelType] = price;
        }
        
        final responseData = {
          'success': true,
          'data': formattedData,
          'last_updated': latestTimestamp.isNotEmpty ? latestTimestamp : now.toIso8601String(),
        };
        
        // Cache the data
        prefs.setString(_cachePricesKey, json.encode(responseData));
        prefs.setString(_cacheTimeKey, now.toIso8601String());
        
        return responseData;
      } else {
        print('Failed to fetch data from Supabase: ${response.statusCode}');
        print('Response body: ${response.body}');
        return _fallbackToPreviousPricesOrGenerate(prefs);
      }
    } catch (e) {
      print('Error fetching fuel prices from Supabase: $e');
      return _fallbackToPreviousPricesOrGenerate(prefs);
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
  
  Map<String, dynamic> _convertSimpleApiToFuelPrices(Map<String, dynamic> apiData) {
    final responseData = <String, Map<String, double>>{};
    
    try {
      print('Converting API data: ${apiData.keys}');
      
      // Extract prices from the simpler API response
      double petrolPrice = 96.72;  // Default values
      double dieselPrice = 89.62;
      double cngPrice = 76.59;
      
      // Try to extract from new API format
      if (apiData.containsKey('prices')) {
        final prices = apiData['prices'];
        if (prices is Map) {
          if (prices.containsKey('petrol')) {
            petrolPrice = _extractPriceFromData(prices['petrol']);
          }
          if (prices.containsKey('diesel')) {
            dieselPrice = _extractPriceFromData(prices['diesel']);
          }
          if (prices.containsKey('cng')) {
            cngPrice = _extractPriceFromData(prices['cng']);
          }
        }
      }
      
      print('Extracted prices: Petrol: $petrolPrice, Diesel: $dieselPrice, CNG: $cngPrice');
      
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
    
    if (priceData == null) {
      print("No price data available, returning original companies");
      return companies;
    }
    
    final updatedCompanies = List<FuelCompany>.from(companies);
    
    try {
      // Handle different possible formats of the price data
      if (priceData.containsKey('data')) {
        // API format with data field
        final companyData = priceData['data'];
        _updateCompaniesFromData(updatedCompanies, companyData);
      } else if (priceData.containsKey('prices')) {
        // Scraped format with prices field
        final Map<String, dynamic> pricesMap = priceData['prices'] as Map<String, dynamic>;
        // Convert scraped data format to a format that can be used
        final convertedData = _convertScrapedDataToCompanyFormat(pricesMap);
        _updateCompaniesFromData(updatedCompanies, convertedData);
      }
    } catch (e) {
      print('Error updating companies with prices: $e');
    }
    
    return updatedCompanies;
  }
  
  void _updateCompaniesFromData(List<FuelCompany> companies, Map<String, dynamic> companyData) {
    for (var i = 0; i < companies.length; i++) {
      final company = companies[i];
      final companyType = company.type.toString().split('.').last.toLowerCase();
      final apiCompanyData = companyData[companyType];
      
      if (apiCompanyData == null) continue;
      
      final updatedPrices = Map<String, double>.from(company.fuelPrices);
      
      apiCompanyData.forEach((String fuelType, dynamic price) {
        if (updatedPrices.containsKey(fuelType)) {
          updatedPrices[fuelType] = price is double ? price : (price is int ? price.toDouble() : double.tryParse(price.toString()) ?? updatedPrices[fuelType]!);
        }
      });
      
      companies[i] = FuelCompany(
        type: company.type,
        name: company.name,
        shortName: company.shortName,
        icon: company.icon,
        fuelPrices: updatedPrices,
        supportsCNG: company.supportsCNG,
      );
    }
  }
  
  Map<String, Map<String, dynamic>> _convertScrapedDataToCompanyFormat(Map<String, dynamic> scrapedPrices) {
    // Find base prices for petrol, diesel and CNG
    double? petrolPrice;
    double? dieselPrice;
    double? cngPrice;
    
    scrapedPrices.forEach((key, value) {
      if (key.toLowerCase().contains('petrol')) {
        petrolPrice = petrolPrice == null ? value : petrolPrice;
      } else if (key.toLowerCase().contains('diesel')) {
        dieselPrice = dieselPrice == null ? value : dieselPrice;
      } else if (key.toLowerCase().contains('cng')) {
        cngPrice = cngPrice == null ? value : cngPrice;
      }
    });
    
    // If no prices found, use defaults
    petrolPrice ??= 96.72;
    dieselPrice ??= 89.62;
    cngPrice ??= 76.59;
    
    // Create a company data format similar to what's expected
    final companyData = <String, Map<String, dynamic>>{
      'iocl': {
        'petrol': petrolPrice,
        'diesel': dieselPrice,
      },
      'bpcl': {
        'petrol': petrolPrice - 0.3,
        'diesel': dieselPrice - 0.4,
      },
      'hpcl': {
        'petrol': petrolPrice - 0.1,
        'diesel': dieselPrice - 0.1,
      },
      'reliance': {
        'petrol': petrolPrice + 0.4,
        'diesel': dieselPrice + 0.5,
      },
      'nayara': {
        'petrol': petrolPrice + 0.2,
        'diesel': dieselPrice + 0.2,
      },
      'shell': {
        'petrol': petrolPrice + 1.8,
        'diesel': dieselPrice + 1.8,
      },
      'igl': {'cng': cngPrice},
      'mgl': {'cng': cngPrice - 3.1},
      'adani': {'cng': cngPrice + 1.7},
    };
    
    return companyData;
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
