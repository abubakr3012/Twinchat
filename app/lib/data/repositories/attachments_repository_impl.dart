import 'dart:io';

import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachments_repository.dart';
import '../datasources/attachments_remote.dart';
import '../mappers/attachments_mapper.dart';

class AttachmentsRepositoryImpl implements AttachmentsRepository {
  AttachmentsRepositoryImpl(this._remote);
  final AttachmentsRemote _remote;

  @override
  Future<Attachment> upload({required File file, int? messageId}) async {
    final dto = await _remote.upload(file: file, messageId: messageId);
    return dto.toDomain();
  }

  @override
  Future<List<Attachment>> listForMessage(int messageId) async {
    final dtos = await _remote.listForMessage(messageId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<void> delete(int id) => _remote.delete(id);
}