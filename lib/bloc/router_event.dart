import 'package:equatable/equatable.dart';
import '../models/router_model.dart';

abstract class RouterEvent extends Equatable {
  const RouterEvent();

  @override
  List<Object?> get props => [];
}

class LoadRouters extends RouterEvent {}

class AddRouter extends RouterEvent {
  final RouterModel router;
  const AddRouter(this.router);

  @override
  List<Object?> get props => [router];
}

class UpdateRouter extends RouterEvent {
  final RouterModel router;
  const UpdateRouter(this.router);

  @override
  List<Object?> get props => [router];
}

class DeleteRouter extends RouterEvent {
  final int id;
  const DeleteRouter(this.id);

  @override
  List<Object?> get props => [id];
}
