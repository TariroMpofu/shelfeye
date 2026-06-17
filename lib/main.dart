import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'services/app_state.dart';
import 'screens/kiosk/kiosk_shell.dart';
import 'utils/log_buffer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Capture debugPrint to a 7-day on-device log so staff can send diagnostics
  // from Settings (invisible in release otherwise).
  await LogBuffer.install();
  // Kiosk: use only the bundled .ttf fonts — never fetch over the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Kiosk hardware (NQuire 750 / NLS MT90) is mounted in landscape.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  );
  // Dedicated kiosk: hide the Android status & navigation bars for full screen
  // (immersiveSticky lets a swipe reveal them briefly, then they auto-hide).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final appState = AppState();
  await appState.loadConfig();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const ShelfEyeApp(),
    ),
  );
}

class ShelfEyeApp extends StatelessWidget {
  const ShelfEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfLine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const KioskShell(),
    );
  }
}
