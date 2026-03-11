import 'package:equatable/equatable.dart';
import '../models/router_model.dart';

abstract class RouterState extends Equatable {
  const RouterState();

  @override
  List<Object?> get props => [];
}

class RouterInitial extends RouterState {}

class RouterLoading extends RouterState {}

class RouterLoaded extends RouterState {
  final List<RouterModel> routers;
  const RouterLoaded(this.routers);

  @override
  List<Object?> get props => [routers];
}

class RouterError extends RouterState {
  final String message;
  const RouterError(this.message);

  @override
  List<Object?> get props => [message];
}
