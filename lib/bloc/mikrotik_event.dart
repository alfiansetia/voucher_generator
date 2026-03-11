import 'package:equatable/equatable.dart';
import '../models/router_model.dart';

abstract class MikrotikEvent extends Equatable {
  const MikrotikEvent();

  @override
  List<Object?> get props => [];
}

class ConnectMikrotik extends MikrotikEvent {
  final RouterModel router;

  const ConnectMikrotik(this.router);

  @override
  List<Object?> get props => [router];
}

class DisconnectMikrotik extends MikrotikEvent {}

class CheckConnectionStatus extends MikrotikEvent {}

class FetchMikrotikResources extends MikrotikEvent {}
