
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Map<String, dynamic>> scrapeLatestPrices() async {
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
          return {'success': true, 'data': cachedData};
        }
      }
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
      );
      
      print('Scraping status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final priceData = _extractPricesFromHTML(document);
        
        if (priceData.isNotEmpty) {
          // Cache the scraped data
          prefs.setString(_cacheScrapedPricesKey, priceData.toString());
          prefs.setString(_cacheScrapedTimeKey, now.toIso8601String());
          
          return {'success': true, 'data': priceData};
        } else {
          print('Failed to extract prices from HTML');
          return {'success': false, 'error': 'No prices found on the page'};
        }
      } else {
        print('Failed to scrape website: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP error ${response.statusCode}'};
      }
    } catch (e) {
      print('Error scraping fuel prices: $e');
      return {'success': false, 'error': e.toString()};
    }
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
