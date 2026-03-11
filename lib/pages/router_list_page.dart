import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/router_bloc.dart';
import '../bloc/router_event.dart';
import '../bloc/router_state.dart';
import '../models/router_model.dart';

class RouterListPage extends StatelessWidget {
  const RouterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MikroTik Routers'),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
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
            if (state.routers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.router, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No routers found. Add one!'),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.routers.length,
              itemBuilder: (context, index) {
                final router = state.routers[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.router, color: Colors.white),
                    ),
                    title: Text(
                      router.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${router.ip}:${router.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showAddDialog(context, router: router),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<RouterBloc>().add(
                              DeleteRouter(router.id!),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // Logic to Connect to Mikrotik
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connecting to ${router.name}...'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else if (state is RouterError) {
            return Center(child: Text(state.message));
          }
          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, {RouterModel? router}) {
    final nameController = TextEditingController(text: router?.name);
    final ipController = TextEditingController(text: router?.ip);
    final userController = TextEditingController(text: router?.username);
    final passController = TextEditingController(text: router?.password);
    final portController = TextEditingController(
      text: router?.port.toString() ?? '8728',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(router == null ? 'Add Router' : 'Edit Router'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address'),
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: 'Port (default 8728)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRouter = RouterModel(
                id: router?.id,
                name: nameController.text,
                ip: ipController.text,
                username: userController.text,
                password: passController.text,
                port: int.tryParse(portController.text) ?? 8728,
              );

              if (router == null) {
                context.read<RouterBloc>().add(AddRouter(newRouter));
              } else {
                context.read<RouterBloc>().add(UpdateRouter(newRouter));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
