
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'models/theme_provider.dart';
import 'models/calculation_history_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ChangeNotifierProvider(create: (_) => CalculationHistoryProvider(prefs)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Fuel Calculator Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.grey[50],
          iconTheme: const IconThemeData(color: Color(0xFF1E88E5)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF424242), 
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Display',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF121212),
          iconTheme: IconThemeData(color: Color(0xFF1E88E5)),
          titleTextStyle: TextStyle(
            color: Colors.white, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Display',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
