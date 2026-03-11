import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/router_bloc.dart';
import 'bloc/mikrotik_bloc.dart';
import 'pages/router_list_page.dart';
import 'repositories/router_repository.dart';
import 'repositories/mikrotik_repository.dart';

void main() {
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
        ],
        child: MaterialApp(
          title: 'Voucher Generator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const RouterListPage(),
        ),
      ),
    );
  }
}
