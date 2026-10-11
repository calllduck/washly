class OrderChatMessage {
  final int id;
  final int orderId;
  final int senderId;
  final String senderRole;
  final String senderName;
  final String text;
  final bool isRead;
  final bool isMine;
  final DateTime createdAt;

  OrderChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.isRead,
    required this.isMine,
    required this.createdAt,
  });

  factory OrderChatMessage.fromJson(Map<String, dynamic> json) {
    return OrderChatMessage(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      senderId: json['senderId'] as int,
      senderRole: json['senderRole'] as String? ?? 'CUSTOMER',
      senderName: json['senderName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
    );
  }
}

class OrderChatThread {
  final int orderId;
  final String status;
  final String storeName;
  final String? storeImageUrl;
  final String customerName;
  final List<OrderChatMessage> messages;

  OrderChatThread({
    required this.orderId,
    required this.status,
    required this.storeName,
    this.storeImageUrl,
    required this.customerName,
    required this.messages,
  });

  factory OrderChatThread.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? {};
    final list = (json['messages'] as List<dynamic>? ?? [])
        .map((m) => OrderChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return OrderChatThread(
      orderId: order['id'] as int? ?? 0,
      status: order['status'] as String? ?? '',
      storeName: order['storeName'] as String? ?? '',
      storeImageUrl: order['storeImageUrl'] as String?,
      customerName: order['customerName'] as String? ?? '',
      messages: list,
    );
  }
}
