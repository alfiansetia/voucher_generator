import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/router_bloc.dart';
import 'pages/router_list_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RouterBloc(),
      child: MaterialApp(
        title: 'Voucher Generator',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const RouterListPage(),
      ),
    );
  }
}
