import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/router_bloc.dart';
import '../bloc/router_event.dart';
import '../bloc/router_state.dart';
import '../bloc/mikrotik_bloc.dart';
import '../bloc/mikrotik_event.dart';
import '../bloc/mikrotik_state.dart';
import '../components/ping_dialog.dart';
import '../components/router_card.dart';
import '../core/constants/app_constants.dart';
import '../models/router_model.dart';
import 'dashboard_page.dart';
import 'home_page.dart';

class RouterListPage extends StatelessWidget {
  const RouterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MikrotikBloc, MikrotikState>(
      listener: (context, state) {
        if (state is MikrotikConnecting) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Connecting to MikroTik...'),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Dispatch disconnect to stop the connection attempt
                          context.read<MikrotikBloc>().add(
                            DisconnectMikrotik(),
                          );
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (state is MikrotikConnected) {
          // Close loading dialog if it's on top
          // Using Navigator.pop(context) is safer here if we know the dialog is the only thing above us
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        } else if (state is MikrotikError) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is MikrotikDisconnected) {
          // If we were connecting and the state becomes disconnected, close the dialog
          // We check if the current route is a dialog by checking if it can pop
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.routerListTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<RouterBloc, RouterState>(
          builder: (context, state) {
            if (state is RouterInitial) {
              context.read<RouterBloc>().add(LoadRouters());
              return const Center(child: CircularProgressIndicator());
            } else if (state is RouterLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RouterLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<RouterBloc>().add(LoadRouters());
                },
                child: state.routers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: state.routers.length,
                        itemBuilder: (context, index) {
                          final router = state.routers[index];
                          return RouterCard(
                            router: router,
                            onTap: () =>
                                _showAddDialog(context, router: router),
                            onPing: () => _showPingDialog(context, router.ip),
                            onConnect: () {
                              context.read<MikrotikBloc>().add(
                                ConnectMikrotik(router),
                              );
                            },
                            onDismissed: (direction) {
                              context.read<RouterBloc>().add(
                                DeleteRouter(router.id!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${router.name} deleted'),
                                ),
                              );
                            },
                            confirmDismiss: (direction) =>
                                _confirmDelete(context, router.name),
                          );
                        },
                      ),
              );
            } else if (state is RouterError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          backgroundColor: AppConstants.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 200),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.router, size: 64, color: AppConstants.greyColor),
              SizedBox(height: AppConstants.defaultPadding),
              Text('No routers found. Add one!'),
              Text(
                'Pull down to refresh',
                style: TextStyle(color: AppConstants.greyColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPingDialog(BuildContext context, String ip) {
    showDialog(
      context: context,
      builder: (context) => PingDialog(ip: ip),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: Text("Are you sure you want to delete $name?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("DELETE", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, {RouterModel? router}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: router?.name);
    final ipController = TextEditingController(text: router?.ip);
    final userController = TextEditingController(text: router?.username);
    final passController = TextEditingController(text: router?.password);
    final portController = TextEditingController(
      text:
          router?.port.toString() ??
          AppConstants.defaultMikrotikPort.toString(),
    );

    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(router == null ? 'Add Router' : 'Edit Router'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.dialogRadius),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. My Router',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  TextFormField(
                    controller: ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      hintText: 'e.g. 192.168.88.1',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'IP is required'
                        : null,
                  ),
                  TextFormField(
                    controller: userController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Username is required'
                        : null,
                  ),
                  TextFormField(
                    controller: passController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscurePassword,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Password is required'
                        : null,
                  ),
                  TextFormField(
                    controller: portController,
                    decoration: const InputDecoration(
                      labelText: 'Port (default 8728)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Port is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Must be a number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newRouter = RouterModel(
                    id: router?.id,
                    name: nameController.text,
                    ip: ipController.text,
                    username: userController.text,
                    password: passController.text,
                    port: int.parse(portController.text),
                  );

                  if (router == null) {
                    context.read<RouterBloc>().add(AddRouter(newRouter));
                  } else {
                    context.read<RouterBloc>().add(UpdateRouter(newRouter));
                  }
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
