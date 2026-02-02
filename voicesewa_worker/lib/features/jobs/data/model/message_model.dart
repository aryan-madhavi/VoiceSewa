import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String originalMsg;
  final Map<String, String> translatedLanguages;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.originalMsg,
    required this.translatedLanguages,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, String> translations = {};
    if (data['translatedLanguages'] != null) {
      data['translatedLanguages'].forEach((key, value) {
        translations[key] = value.toString();
      });
    }

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      originalMsg: data['originalMsg'] ?? '',
      translatedLanguages: translations,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getLocalizedMessage(String preferredLangCode) {
    final keyMap = {
      'en': 'engMsg',
      'hi': 'hinMsg',
      'gu': 'gujMsg',
      'mr': 'marMsg'
    };

    final key = keyMap[preferredLangCode] ?? 'engMsg';
    return translatedLanguages[key]?.isNotEmpty == true
        ? translatedLanguages[key]!
        : originalMsg;
  }
}