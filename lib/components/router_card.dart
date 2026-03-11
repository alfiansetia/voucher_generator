import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/router_model.dart';

class RouterCard extends StatelessWidget {
  final RouterModel router;
  final VoidCallback onTap;
  final VoidCallback onPing;
  final VoidCallback onConnect;
  final Function(DismissDirection) onDismissed;
  final Future<bool?> Function(DismissDirection) confirmDismiss;

  const RouterCard({
    super.key,
    required this.router,
    required this.onTap,
    required this.onPing,
    required this.onConnect,
    required this.onDismissed,
    required this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(router.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: AppConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: onDismissed,
      confirmDismiss: confirmDismiss,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppConstants.primaryColor,
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
                icon: const Icon(Icons.network_ping, color: Colors.orange),
                onPressed: onPing,
                tooltip: 'Ping',
              ),
              IconButton(
                icon: const Icon(Icons.login, color: Colors.green),
                onPressed: onConnect,
                tooltip: 'Connect',
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
