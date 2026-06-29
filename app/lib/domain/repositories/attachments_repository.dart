import 'dart:io';

import '../entities/attachment.dart';

abstract class AttachmentsRepository {
  Future<Attachment> upload({
    required File file,
    int? messageId,
  });
  Future<List<Attachment>> listForMessage(int messageId);
  Future<void> delete(int id);
}
