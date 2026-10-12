import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/scope.dart';
import 'core/theme.dart';
import 'data/fan_store.dart';
import 'firebase_options.dart';
import 'ui/pages/shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = false;
  String? initializationError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseEnabled = true;
  } on StateError {
    // No Firebase configuration: use the persistent local profile.
  } catch (_) {
    initializationError = 'Não foi possível iniciar a conexão com a nuvem. O aplicativo abriu no modo local.';
  }
  final store = FanStore(firebaseEnabled: firebaseEnabled);
  await store.bootstrap();
  store.cloudError = initializationError;
  runApp(FanApp(store: store));
}

class FanApp extends StatefulWidget {
  const FanApp({super.key, required this.store});
  final FanStore store;

  @override
  State<FanApp> createState() => _FanAppState();
}

class _FanAppState extends State<FanApp> {
  @override
  void dispose() { widget.store.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FanScope(
    store: widget.store,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FAN · Histórias que conectam',
      theme: fanTheme(),
      home: const ShellPage(),
    ),
  );
}
