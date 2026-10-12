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
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseEnabled = true;
  } catch (_) {
    // The ZIP works without credentials in a visibly identified demo mode.
    // Real accounts and cloud writes become available after flutterfire configure.
  }
  final store = FanStore(firebaseEnabled: firebaseEnabled);
  await store.bootstrap();
  runApp(FanApp(store: store));
}

class FanApp extends StatelessWidget {
  const FanApp({super.key, required this.store});
  final FanStore store;

  @override
  Widget build(BuildContext context) => FanScope(
    store: store,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FAN · Histórias que conectam',
      theme: fanTheme(),
      home: const ShellPage(),
    ),
  );
}
