import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_app/core/auth_session.dart';
import 'package:smart_app/repositories/dashboard_repository.dart';
import 'package:smart_app/view/home.dart';
import 'package:smart_app/view/login_page.dart';
import 'package:smart_app/vm/dashboard_viewmodel.dart';

void main() {
  runApp(const OwnerApp());
}

class OwnerApp extends StatefulWidget {
  const OwnerApp({super.key});

  @override
  State<OwnerApp> createState() => _OwnerAppState();
}

class _OwnerAppState extends State<OwnerApp> {
  late final Future<void> restoreSession = AuthSession.restore();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(DashboardRepository()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Harvest Slot 점주앱',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff215C42),
            primary: const Color(0xff215C42),
            secondary: const Color(0xffF4C95D),
            surface: const Color(0xffFCFEFA),
          ),
          scaffoldBackgroundColor: const Color(0xffF7FAF4),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffDAE4D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffDAE4D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xff215C42),
                width: 1.4,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xffDFF4E8),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
        home: FutureBuilder<void>(
          future: restoreSession,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return AuthSession.isLoggedIn ? const Home() : const LoginPage();
          },
        ),
      ),
    );
  }
}
