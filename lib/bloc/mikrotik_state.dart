import 'package:equatable/equatable.dart';
import '../models/router_model.dart';

abstract class MikrotikState extends Equatable {
  const MikrotikState();

  @override
  List<Object?> get props => [];
}

class MikrotikInitial extends MikrotikState {}

class MikrotikConnecting extends MikrotikState {
  final RouterModel router;
  const MikrotikConnecting(this.router);

  @override
  List<Object?> get props => [router];
}

class MikrotikConnected extends MikrotikState {
  final RouterModel router;
  final Map<String, String>? resources;
  const MikrotikConnected(this.router, {this.resources});

  @override
  List<Object?> get props => [router, resources];
}

class MikrotikDisconnected extends MikrotikState {}

class MikrotikError extends MikrotikState {
  final String message;
  const MikrotikError(this.message);

  @override
  List<Object?> get props => [message];
}
