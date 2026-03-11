import '../core/exceptions/router_exception.dart';
import '../database/router_db.dart';
import '../models/router_model.dart';

class RouterRepository {
  final RouterDB _db = RouterDB.instance;

  Future<List<RouterModel>> getRouters() async {
    try {
      return await _db.getAllRouters();
    } catch (e) {
      throw DatabaseException('Failed to fetch routers: $e');
    }
  }

  Future<int> addRouter(RouterModel router) async {
    try {
      return await _db.insertRouter(router);
    } catch (e) {
      throw DatabaseException('Failed to add router: $e');
    }
  }

  Future<int> updateRouter(RouterModel router) async {
    try {
      return await _db.updateRouter(router);
    } catch (e) {
      throw DatabaseException('Failed to update router: $e');
    }
  }

  Future<int> deleteRouter(int id) async {
    try {
      return await _db.deleteRouter(id);
    } catch (e) {
      throw DatabaseException('Failed to delete router: $e');
    }
  }
}
