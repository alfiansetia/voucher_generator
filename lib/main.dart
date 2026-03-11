import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/router_bloc.dart';
import 'bloc/mikrotik_bloc.dart';
import 'bloc/theme_bloc.dart';
import 'pages/splash_screen.dart';
import 'repositories/router_repository.dart';
import 'repositories/mikrotik_repository.dart';

import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize network tools path
  final appDocDir = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDir.path);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => RouterRepository()),
        RepositoryProvider(create: (context) => MikrotikRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                RouterBloc(repository: context.read<RouterRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                MikrotikBloc(repository: context.read<MikrotikRepository>()),
          ),
          BlocProvider(create: (context) => ThemeBloc()..add(LoadThemeEvent())),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return MaterialApp(
              title: 'Network Tool',
              debugShowCheckedModeBanner: false,
              themeMode: state.themeMode,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
              ),
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
