import '../entities/call.dart';

abstract class CallsRepository {
  Future<List<Call>> list();
  Future<Call> getById(int id);
  Future<Call> create({required int chatId, required CallType type});
  Future<void> accept(int id);
  Future<void> reject(int id);
  Future<void> end(int id);
  Future<void> leave(int id);
}
