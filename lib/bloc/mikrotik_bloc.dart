import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/mikrotik_repository.dart';
import 'mikrotik_event.dart';
import 'mikrotik_state.dart';

class MikrotikBloc extends Bloc<MikrotikEvent, MikrotikState> {
  final MikrotikRepository repository;

  MikrotikBloc({required this.repository}) : super(MikrotikInitial()) {
    on<ConnectMikrotik>(_onConnect);
    on<DisconnectMikrotik>(_onDisconnect);
    on<FetchMikrotikResources>(_onFetchResources);
    on<CheckConnectionStatus>(_onCheckStatus);
  }

  Future<void> _onConnect(
    ConnectMikrotik event,
    Emitter<MikrotikState> emit,
  ) async {
    emit(MikrotikConnecting(event.router));
    try {
      await repository.connect(event.router);
      emit(MikrotikConnected(event.router));
      // Trigger resource fetch separately so it doesn't block the UI transition
      add(FetchMikrotikResources());
    } catch (e) {
      emit(MikrotikError(e.toString()));
    }
  }

  Future<void> _onFetchResources(
    FetchMikrotikResources event,
    Emitter<MikrotikState> emit,
  ) async {
    if (state is MikrotikConnected) {
      final currentState = state as MikrotikConnected;
      try {
        final resources = await repository.getSystemResource();
        emit(MikrotikConnected(currentState.router, resources: resources));
      } catch (e) {
        // We don't want to emit an error state here because we're still connected
        // Maybe log it or handle it differently
      }
    }
  }

  Future<void> _onDisconnect(
    DisconnectMikrotik event,
    Emitter<MikrotikState> emit,
  ) async {
    await repository.disconnect();
    emit(MikrotikDisconnected());
  }

  void _onCheckStatus(
    CheckConnectionStatus event,
    Emitter<MikrotikState> emit,
  ) {
    if (repository.isConnected && repository.currentRouter != null) {
      // If we're connected but check status, we don't have resources yet
      // unless we emit the old ones or fetch new ones.
      // For simplicity, let's just emit connected.
      emit(MikrotikConnected(repository.currentRouter!));
    } else {
      emit(MikrotikDisconnected());
    }
  }
}
