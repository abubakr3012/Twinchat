import 'package:dio/dio.dart';

import '../models/auth_dto.dart';

class UsersRemote {
  UsersRemote(this._dio);
  final Dio _dio;

  Future<UserDto> me() async {
    final res = await _dio.get<Map<String, dynamic>>('users/me/');
    return UserDto.fromJson(res.data ?? const {});
  }

  Future<UserDto> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('users/$id/');
    return UserDto.fromJson(res.data ?? const {});
  }

  Future<List<UserDto>> search(String query) async {
    final res = await _dio.get<List<dynamic>>(
      'users/search/',
      queryParameters: {'q': query},
    );
    return (res.data ?? const <dynamic>[])
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserDto> update({
    String? username,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (avatarUrl != null) body['avatar'] = avatarUrl;
    if (bio != null) body['bio'] = bio;
    final res = await _dio.patch<Map<String, dynamic>>('users/me/', data: body);
    return UserDto.fromJson(res.data ?? const {});
  }
}
