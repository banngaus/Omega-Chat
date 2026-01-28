import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // TODO: вынести в конфиг или .env
  static const String baseUrl = 'http://26.81.184.119:8000';
  
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  //АУТЕНТИФИКАЦИЯ

  Future<void> register(String username, String email, String password) async {
    try {
      await _dio.post('/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка регистрации');
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data['access_token'];
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка входа');
    }
  }

  //ПРОФИЛЬ

  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await _dio.get(
        '/me',
        queryParameters: {'token': token},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка загрузки профиля');
    }
  }

  Future<void> updateAvatar(String token, String url) async {
    try {
      await _dio.post(
        '/me/avatar',
        queryParameters: {'token': token},
        data: {'avatar_url': url},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка обновления аватара');
    }
  }

  Future<void> updateProfile(String token, {String? username, String? status}) async {
    try {
      await _dio.patch(
        '/me',
        queryParameters: {'token': token},
        data: {
          if (username != null) 'username': username,
          if (status != null) 'status': status,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка обновления профиля');
    }
  }

  //ЧАТЫ 

  Future<List<dynamic>> getDirectChats(String token) async {
    try {
      final response = await _dio.get(
        '/me/directs',
        queryParameters: {'token': token},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка загрузки чатов');
    }
  }

  /// Создать новый чат
  Future<Map<String, dynamic>> createDirectChat(String token, String username) async {
    try {
      final users = await searchUsers(token, username);
      
      if (users.isEmpty) {
        throw Exception('Пользователь не найден');
      }

      final targetUser = users.first;
      final chatId = await startDirectChat(token, targetUser['id']);

      return {
        'id': chatId,
        'name': targetUser['username'],
        'avatar_url': targetUser['avatar_url'],
      };
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка создания чата');
    }
  }

  /// Поиск пользователей
  Future<List<dynamic>> searchUsers(String token, String query) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {
          'token': token,
          'q': query,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка поиска');
    }
  }

  /// Начать чат
  Future<int> startDirectChat(String token, int userId) async {
    try {
      final response = await _dio.post(
        '/direct/start',
        queryParameters: {
          'token': token,
          'target_user_id': userId,
        },
      );
      return response.data['id'];
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка создания чата');
    }
  }

  ///историю сообщений
  Future<List<dynamic>> getChatMessages(String token, int chatId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/chats/$chatId/messages',
        queryParameters: {
          'token': token,
          'limit': limit,
          'offset': offset,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка загрузки сообщений');
    }
  }

  // ФАЙЛЫ 

  Future<String> uploadFile(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post('/upload', data: formData);
      
      final url = response.data['url'];
      return url.startsWith('http') ? url : baseUrl + url;
    } on DioException catch (e) {
      throw _handleError(e, 'Ошибка загрузки файла');
    }
  }

  //  ОБРАБОТКА ОШИБОК

  Exception _handleError(DioException e, String defaultMessage) {
    String message = defaultMessage;

    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        message = data['detail'].toString();
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Превышено время ожидания';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Нет подключения к серверу';
    }

    debugPrint('API Error: $message (${e.response?.statusCode})');
    return Exception(message);
  }
}