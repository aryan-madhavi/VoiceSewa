import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final Map<String, dynamic> participantsData;
  final String lastMessage;
  final DateTime lastUpdated;

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.participantsData,
    required this.lastMessage,
    required this.lastUpdated,
  });


  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoomModel(
        roomId: doc.id,
        participants: List<String>.from(data['participants'] ?? []),
        participantsData: Map<String, dynamic>.from(data['participantData'] ?? {}),
        lastMessage: (data['lastMessage'] != null && data['lastMessage']['original'] != null)
            ? data['lastMessage']['original']
            : '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}