import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'data/database/hive_service.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/room_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/loyalty_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/loyalty_provider.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable auto-rotation - only portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await HiveService.init();
  runApp(const HotelVistaApp());
}

class HotelVistaApp extends StatefulWidget {
  const HotelVistaApp({super.key});

  @override
  State<HotelVistaApp> createState() => _HotelVistaAppState();
}

class _HotelVistaAppState extends State<HotelVistaApp> {
  late final UserRepository _userRepo;
  late final RoomRepository _roomRepo;
  late final BookingRepository _bookingRepo;
  late final LoyaltyRepository _loyaltyRepo;

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _roomRepo = RoomRepository();
    _loyaltyRepo = LoyaltyRepository(_userRepo);
    _bookingRepo = BookingRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserRepository>.value(value: _userRepo),
        Provider<RoomRepository>.value(value: _roomRepo),
        Provider<BookingRepository>.value(value: _bookingRepo),
        Provider<LoyaltyRepository>.value(value: _loyaltyRepo),
        ChangeNotifierProvider(create: (_) => AuthProvider(_userRepo)),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(_bookingRepo, _loyaltyRepo),
        ),
        ChangeNotifierProvider(create: (_) => RoomProvider(_roomRepo, _bookingRepo)),
        ChangeNotifierProvider(
          create: (_) => LoyaltyProvider(_loyaltyRepo, _userRepo),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final _router = buildRouter(context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'vista',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
    );
  }
}
