import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/shared/home_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/grid_editor_screen.dart';
import 'screens/admin/grid_setup_screen.dart';
import 'screens/admin/org_registration_screen.dart';
import 'screens/visitor/visitor_home_screen.dart';
import 'screens/visitor/visitor_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const GridMapApp());
}

class GridMapApp extends StatelessWidget {
  const GridMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
        GoRoute(
          path: '/verify-email',
          builder: (_, state) => VerifyEmailScreen(
            email: state.uri.queryParameters['email'],
          ),
        ),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
        GoRoute(
            path: '/admin/register',
            builder: (_, __) => const OrgRegistrationScreen()),
        GoRoute(
            path: '/admin/grid-setup',
            builder: (_, __) => const GridSetupScreen()),
        GoRoute(
            path: '/admin/editor',
            builder: (_, __) => const GridEditorScreen()),
        GoRoute(
    path: '/visitor',
    builder: (_, __) => const VisitorHomeScreen()),
GoRoute(
    path: '/visitor/map/:id',
    builder: (_, state) =>
        VisitorMapScreen(buildingId: state.pathParameters['id']!)),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp.router(
        title: 'GridMap AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}