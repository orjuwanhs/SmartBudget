import 'package:cloud_firestore/cloud_firestore.dart';
class AppNotification {

  final String? id;
  final String title;
  final String body;
  final String type;

  final bool isRead;

  final DateTime? timestamp;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.timestamp,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppNotification(

      id: doc.id,

      title: data['title'] ?? '',

      body: data['body'] ?? '',

      type: data['type'] ?? '',

      isRead: data['is_read'] ?? false,

      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),

    );

  }

  Map<String, dynamic> toFirestore() {

    return {

      "title": title,

      "body": body,

      "type": type,

      "is_read": isRead,

      "timestamp": FieldValue.serverTimestamp(),

    };

  }

}

