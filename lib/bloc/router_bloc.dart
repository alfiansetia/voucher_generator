import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/router_db.dart';
import 'router_event.dart';
import 'router_state.dart';

class RouterBloc extends Bloc<RouterEvent, RouterState> {
  final RouterDB db = RouterDB.instance;

  RouterBloc() : super(RouterInitial()) {
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
      final routers = await db.getAllRouters();
      emit(RouterLoaded(routers));
    } catch (e) {
      emit(RouterError(e.toString()));
    }
  }

  Future<void> _onAddRouter(AddRouter event, Emitter<RouterState> emit) async {
    try {
      await db.insertRouter(event.router);
      add(LoadRouters());
    } catch (e) {
      emit(RouterError(e.toString()));
    }
  }

  Future<void> _onUpdateRouter(
    UpdateRouter event,
    Emitter<RouterState> emit,
  ) async {
    try {
      await db.updateRouter(event.router);
      add(LoadRouters());
    } catch (e) {
      emit(RouterError(e.toString()));
    }
  }

  Future<void> _onDeleteRouter(
    DeleteRouter event,
    Emitter<RouterState> emit,
  ) async {
    try {
      await db.deleteRouter(event.id);
      add(LoadRouters());
    } catch (e) {
      emit(RouterError(e.toString()));
    }
  }
}
