import 'dart:typed_data';

import '../entities/attachment.dart';

abstract class AttachmentsRepository {
  Future<Attachment> upload({
    required Uint8List bytes,
    required String fileName,
    int? messageId,
  });
  Future<List<Attachment>> listForMessage(int messageId);
  Future<void> delete(int id);
}
