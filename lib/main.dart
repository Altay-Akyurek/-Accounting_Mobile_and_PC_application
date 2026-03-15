import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/database_helper.dart';
import 'services/auth_service.dart';
import 'services/protocol_service.dart';
import 'pages/projects_page.dart';
import 'pages/labor_management_page.dart';
import 'pages/finance_management_page.dart';
import 'pages/splash_screen.dart';
import 'pages/cari_hesap_liste_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/labor_summary_report_page.dart';
import 'pages/premium_page.dart';
import 'services/premium_manager.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/worker_provider.dart';
import 'services/sync_manager.dart';
import 'services/iap_service.dart';
import 'services/ad_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Supabase.initialize(
    url: 'https://dwyeynurzyhjxncafqnz.supabase.co',
    anonKey: 'sb_publishable_v6VWwf7RZtHT7521pcpohQ_-ayN2OdC',
  );

  await initializeDateFormatting('tr_TR', null);
  await DatabaseHelper.instance.init();
  await SyncManager.instance.init();
  
  await PremiumManager.instance.init();
  if (Platform.isAndroid || Platform.isIOS) {
    IAPService.instance.init(); 
  }
  await LanguageService.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: LanguageService.instance.localeNotifier,
        builder: (context, locale, child) {
          return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MuhasebePro',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF011627),
              primary: const Color(0xFF011627),
              secondary: const Color(0xFF2EC4B6),
              tertiary: const Color(0xFFE71D36),
              surface: Colors.white,
              background: const Color(0xFFF0F2F5),
            ),
            scaffoldBackgroundColor: const Color(0xFFF0F2F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF011627),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: const Color(0xFF011627),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2EC4B6), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: -1.0),
              titleLarge: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF011627), letterSpacing: -0.5),
              bodyLarge: TextStyle(color: Color(0xFF333333), fontSize: 16, height: 1.5),
            ),
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [AdHelper.routeObserver],
          home: const AuthWrapper(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
          routes: {
            '/projects': (context) => const ProjectsPage(),
            '/labor': (context) => const LaborManagementPage(),
            '/finance': (context) => const FinanceManagementPage(),
            '/cari_liste': (context) => const CariHesapListePage(),
            '/reset_password': (context) => const ResetPasswordPage(),
            '/labor_summary': (context) => const LaborSummaryReportPage(),
            '/premium': (context) => const PremiumPage(),
          },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final authState = snapshot.data;
        final session = authState?.session;
        final event = authState?.event;

        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordPage();
        }

        if (session != null) {
          final user = session.user;
          final metadata = user.userMetadata ?? {};
          final isDeletedMetadata = metadata['account_deleted'] == true || 
                                    metadata['account_deleted'].toString().toLowerCase() == 'true';
          
          if (isDeletedMetadata) {
            debugPrint('DEBUG: AuthWrapper - Metadata üzerinden SİLİNMİŞ HESAP TESPİTİ!');
            AuthService().signOut();
            return const LoginPage();
          }

          return FutureBuilder<bool>(
            future: _checkIfUserDeletedInSQL(user.id),
            builder: (context, sqlSnapshot) {
              if (sqlSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen(); 
              }

              final isDeletedInSQL = sqlSnapshot.data ?? false;
              
              if (isDeletedInSQL) {
                debugPrint('DEBUG: AuthWrapper - SQL üzerinden SİLİNMİŞ HESAP TESPİTİ!');
                AuthService().signOut();
                return const LoginPage();
              }

              return const HomePage();
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<bool> _checkIfUserDeletedInSQL(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('user_deletion_requests')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }
}
