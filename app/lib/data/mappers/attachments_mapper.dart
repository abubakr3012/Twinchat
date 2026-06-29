import '../../domain/entities/attachment.dart';
import '../models/attachments_dto.dart';

extension AttachmentDtoX on AttachmentDto {
  Attachment toDomain() => Attachment(
        id: id,
        url: url,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
        durationSeconds: durationSeconds,
        thumbnailUrl: thumbnailUrl,
      );
}