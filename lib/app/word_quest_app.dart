import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';

class WordQuestApp extends StatelessWidget {
  const WordQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F7D6D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4EC),
      ),
      home: const HomeScreen(),
    );
  }
}
