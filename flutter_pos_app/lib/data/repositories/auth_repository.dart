import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel> login(String username, String password) async {
    if (username.trim().isEmpty) {
      throw Exception('يرجى إدخال اسم المستخدم');
    }
    if (password.trim().isEmpty) {
      throw Exception('يرجى إدخال كلمة المرور');
    }

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      final token = data['accessToken'] ?? data['token'];

      if (response.statusCode == 200 && token != null) {
        await _storage.write(key: 'accessToken', value: token);
        if (data['refreshToken'] != null) {
          await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        }
        return UserModel.fromJson(data['user']);
      } else {
        throw Exception(data['message'] ?? 'فشل تسجيل الدخول');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final msg = e.response?.data['message'] ?? e.response?.data['error'];
        if (msg != null) {
          throw Exception(msg);
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('تعذر الاتصال بخادم الباك إند، يرجى التحقق من تشغيل السيرفر والشبكة');
      }
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null && token.isNotEmpty;
  }
}
