import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/exceptions/router_exception.dart';
import '../repositories/router_repository.dart';
import 'router_event.dart';
import 'router_state.dart';

class RouterBloc extends Bloc<RouterEvent, RouterState> {
  final RouterRepository repository;

  RouterBloc({required this.repository}) : super(RouterInitial()) {
    on<LoadRouters>(_onLoadRouters);
    on<AddRouter>(_onAddRouter);
    on<UpdateRouter>(_onUpdateRouter);
    on<DeleteRouter>(_onDeleteRouter);
  }

  Future<void> _onLoadRouters(
    LoadRouters event,
    Emitter<RouterState> emit,
  ) async {
    emit(RouterLoading());
    try {
      final routers = await repository.getRouters();
      emit(RouterLoaded(routers));
    } on RouterException catch (e) {
      emit(RouterError(e.message));
    } catch (e) {
      emit(RouterError('An unexpected error occurred: $e'));
    }
  }

  Future<void> _onAddRouter(AddRouter event, Emitter<RouterState> emit) async {
    try {
      await repository.addRouter(event.router);
      add(LoadRouters());
    } on RouterException catch (e) {
      emit(RouterError(e.message));
    } catch (e) {
      emit(RouterError('Failed to add router: $e'));
    }
  }

  Future<void> _onUpdateRouter(
    UpdateRouter event,
    Emitter<RouterState> emit,
  ) async {
    try {
      await repository.updateRouter(event.router);
      add(LoadRouters());
    } on RouterException catch (e) {
      emit(RouterError(e.message));
    } catch (e) {
      emit(RouterError('Failed to update router: $e'));
    }
  }

  Future<void> _onDeleteRouter(
    DeleteRouter event,
    Emitter<RouterState> emit,
  ) async {
    try {
      await repository.deleteRouter(event.id);
      add(LoadRouters());
    } on RouterException catch (e) {
      emit(RouterError(e.message));
    } catch (e) {
      emit(RouterError('Failed to delete router: $e'));
    }
  }
}
