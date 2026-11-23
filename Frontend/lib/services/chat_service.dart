import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/order_chat_message.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class ChatService {
  /// Fetch chat thread and messages for an order.
  Future<OrderChatThread> getMessages(int orderId, {int? sinceId, String channel = 'customer_partner'}) async {
    try {
      final response = await ApiClient.dio.get(
        '/chat/orders/$orderId/messages',
        queryParameters: {
          if (sinceId != null) 'sinceId': sinceId,
          'channel': channel,
        },
      );
      return OrderChatThread.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal memuat pesan chat.'));
    }
  }

  /// Send a new message to the order chat.
  Future<OrderChatMessage> sendMessage(int orderId, String text, {String channel = 'customer_partner'}) async {
    try {
      final response = await ApiClient.dio.post(
        '/chat/orders/$orderId/messages',
        data: {'text': text.trim()},
        queryParameters: {'channel': channel},
      );
      return OrderChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal mengirim pesan chat.'));
    }
  }

  /// Get count of unread messages for an order.
  Future<int> getUnreadCount(int orderId) async {
    try {
      final response = await ApiClient.dio.get('/chat/orders/$orderId/unread');
      final data = response.data;
      if (data is Map && data['unreadCount'] is int) {
        return data['unreadCount'] as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
