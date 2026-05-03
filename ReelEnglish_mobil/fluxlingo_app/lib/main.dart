import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/feed/presentation/screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlangıç ayarları
  await Firebase.initializeApp();

  // media_kit başlangıç ayarları
  MediaKit.ensureInitialized();

  runApp(
    // Riverpod kullanımı için ProviderScope ekliyoruz
    const ProviderScope(child: FluxLingoApp()),
  );
}

class FluxLingoApp extends StatelessWidget {
  const FluxLingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluxLingo',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      debugShowCheckedModeBanner: false,
      home: FeedScreen(),
    );
  }
}
