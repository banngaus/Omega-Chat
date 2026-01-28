import 'package:dio/dio.dart';
import 'package:omega_chat/services/api_service.dart';

class GameService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));

  /// Создать игру
  Future<Map<String, dynamic>> createGame({
    required String token,
    required String gameType,
    int? chatId,
    int? groupId,
  }) async {
    try {
      final response = await _dio.post(
        '/games/create',
        queryParameters: {
          'token': token,
          'game_type': gameType,
          if (chatId != null) 'chat_id': chatId,
          if (groupId != null) 'group_id': groupId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка создания игры');
    }
  }

  /// Присоединиться к игре
  Future<void> joinGame({
    required String token,
    required int sessionId,
  }) async {
    try {
      await _dio.post(
        '/games/$sessionId/join',
        queryParameters: {'token': token},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка присоединения');
    }
  }

  /// Начать игру
  Future<void> startGame({
    required String token,
    required int sessionId,
  }) async {
    try {
      await _dio.post(
        '/games/$sessionId/start',
        queryParameters: {'token': token},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка запуска игры');
    }
  }

  /// Действие в игре
  Future<Map<String, dynamic>> gameAction({
    required String token,
    required int sessionId,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        '/games/$sessionId/action',
        queryParameters: {
          'token': token,
          'action': action,
        },
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка действия');
    }
  }

  /// Завершить игру
  Future<void> endGame({
    required String token,
    required int sessionId,
    int? winnerId,
  }) async {
    try {
      await _dio.post(
        '/games/$sessionId/end',
        queryParameters: {
          'token': token,
          if (winnerId != null) 'winner_id': winnerId,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка завершения');
    }
  }

  /// Получить свою статистику
  Future<List<Map<String, dynamic>>> getMyStats(String token) async {
    try {
      final response = await _dio.get(
        '/games/stats',
        queryParameters: {'token': token},
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Ошибка загрузки статистики');
    }
  }
}