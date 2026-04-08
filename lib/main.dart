import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/home_screen.dart';

Future<void> morpho() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const MorphoApp(),
    ),
  );
}

class MorphoApp extends StatelessWidget {
  const MorphoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morpho',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFD1),
          secondary: Color(0xFFFF6B6B),
          surface: Color(0xFF0A0A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
