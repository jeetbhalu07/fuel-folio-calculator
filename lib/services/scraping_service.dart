
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ScrapingService {
  static const String _baseUrl = "https://www.mypetrolprice.com/";
  static const String _cacheScrapedPricesKey = 'scraped_fuel_prices';
  static const String _cacheScrapedTimeKey = 'scraped_fuel_prices_time';
  static const int _cacheExpiryMinutes = 60; // 1 hour cache expiry

  static final ScrapingService _instance = ScrapingService._internal();
  
  factory ScrapingService() {
    return _instance;
  }
  
  ScrapingService._internal();

  // Check for internet connectivity
  Future<bool> _hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>?> scrapeLatestPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Check cache validity
    final cacheTimeStr = prefs.getString(_cacheScrapedTimeKey);
    if (cacheTimeStr != null) {
      final cacheTime = DateTime.parse(cacheTimeStr);
      final difference = now.difference(cacheTime).inMinutes;
      
      if (difference < _cacheExpiryMinutes) {
        final cachedData = prefs.getString(_cacheScrapedPricesKey);
        if (cachedData != null) {
          print('Using cached scraped fuel prices');
          // Convert the cached string to a Map
          try {
            // Parse the string representation of Map back to an actual Map
            final Map<String, dynamic> parsedData = _stringToMap(cachedData);
            return parsedData;
          } catch (e) {
            print('Error parsing cached data: $e');
            // Continue with scraping if parsing fails
          }
        }
      }
    }
    
    // Check internet connectivity before attempting to scrape
    bool hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      print('No internet connection, using cache if available');
      // Try to use cache even if expired
      final cachedData = prefs.getString(_cacheScrapedPricesKey);
      if (cachedData != null) {
        try {
          return _stringToMap(cachedData);
        } catch (e) {
          print('Error parsing cached data: $e');
          // Return empty data structure when offline and no cache
          return {
            'prices': {},
            'timestamp': now.toIso8601String(),
          };
        }
      }
      // Return empty data structure when offline and no cache
      return {
        'prices': {},
        'timestamp': now.toIso8601String(),
      };
    }
    
    try {
      print('Scraping fuel prices from: $_baseUrl');
      
      // Add a desktop User-Agent to avoid being blocked
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Connection timeout');
          return http.Response('Timeout', 408);
        },
      );
      
      print('Scraping status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final priceData = _extractPricesFromHTML(document);
        
        if (priceData.isNotEmpty) {
          // Cache the scraped data
          await prefs.setString(_cacheScrapedPricesKey, priceData.toString());
          await prefs.setString(_cacheScrapedTimeKey, now.toIso8601String());
          
          return priceData;
        } else {
          print('Failed to extract prices from HTML');
          return _fallbackToCache(prefs);
        }
      } else {
        print('Failed to scrape website: ${response.statusCode}');
        return _fallbackToCache(prefs);
      }
    } catch (e) {
      print('Error scraping fuel prices: $e');
      return _fallbackToCache(prefs);
    }
  }
  
  // Helper method to fall back to cache
  Future<Map<String, dynamic>?> _fallbackToCache(SharedPreferences prefs) async {
    final cachedData = prefs.getString(_cacheScrapedPricesKey);
    if (cachedData != null) {
      try {
        return _stringToMap(cachedData);
      } catch (e) {
        print('Error parsing cached data: $e');
      }
    }
    // Return empty data structure when no cache
    return {
      'prices': {},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Helper method to convert a string representation of a Map back to a Map
  Map<String, dynamic> _stringToMap(String mapString) {
    // Basic conversion of string representation of map to actual map
    Map<String, dynamic> result = {};
    
    try {
      // Remove the curly braces and split into key-value pairs
      String content = mapString.trim();
      if (content.startsWith('{')) content = content.substring(1);
      if (content.endsWith('}')) content = content.substring(0, content.length - 1);
      
      // Extract timestamp if it exists
      final timestampPattern = RegExp(r'timestamp: ([^,}]+)');
      final timestampMatch = timestampPattern.firstMatch(content);
      String? timestamp;
      
      if (timestampMatch != null) {
        timestamp = timestampMatch.group(1);
        // Remove the timestamp part from the content
        content = content.replaceAll(timestampPattern, '');
        if (content.contains('prices: {')) {
          // Handle the case where prices is a nested map
          final pricesPattern = RegExp(r'prices: \{([^}]+)\}');
          final pricesMatch = pricesPattern.firstMatch(content);
          
          if (pricesMatch != null) {
            final pricesContent = pricesMatch.group(1);
            if (pricesContent != null) {
              Map<String, double> prices = {};
              
              // Parse price entries
              final priceEntries = pricesContent.split(',');
              for (var entry in priceEntries) {
                if (entry.trim().isEmpty) continue;
                
                final parts = entry.split(':');
                if (parts.length == 2) {
                  final key = parts[0].trim().replaceAll(RegExp(r'[\'"]'), '');
                  final valueStr = parts[1].trim();
                  
                  try {
                    prices[key] = double.parse(valueStr);
                  } catch (e) {
                    print('Error parsing price value: $valueStr');
                  }
                }
              }
              
              result['prices'] = prices;
            }
          }
        }
        
        // Add timestamp
        if (timestamp != null) {
          result['timestamp'] = timestamp;
        }
      } else {
        // Fallback parsing if the format is different
        result = {'prices': {}, 'timestamp': DateTime.now().toIso8601String()};
      }
    } catch (e) {
      print('Error converting string to map: $e');
      result = {'prices': {}, 'timestamp': DateTime.now().toIso8601String()};
    }
    
    return result;
  }
  
  Map<String, dynamic> _extractPricesFromHTML(Document document) {
    final Map<String, double> prices = {};
    
    try {
      // Extract city name and prices from the homepage
      final cityPriceElements = document.querySelectorAll('.fuel_prices_block');
      
      for (var element in cityPriceElements) {
        // Get city name
        final cityElement = element.querySelector('.fuel_head');
        String city = '';
        if (cityElement != null) {
          city = cityElement.text.trim();
        }
        
        // Get fuel prices
        final priceRows = element.querySelectorAll('.fuel_prices_wh');
        for (var row in priceRows) {
          final f_type = row.querySelector('.fuel_type');
          final f_price = row.querySelector('.fuel_price');
          
          if (f_type != null && f_price != null) {
            final fuelType = f_type.text.trim().toLowerCase();
            final priceText = f_price.text.replaceAll(RegExp(r'[^\d.]'), '');
            
            try {
              final price = double.parse(priceText);
              prices['${city}_$fuelType'] = price;
            } catch (e) {
              print('Error parsing price: $priceText');
            }
          }
        }
      }
      
      print('Extracted prices: $prices');
    } catch (e) {
      print('Error extracting data from HTML: $e');
    }
    
    return {
      'prices': prices,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
