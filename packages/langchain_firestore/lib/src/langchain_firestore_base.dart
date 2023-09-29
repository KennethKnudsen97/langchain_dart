import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:langchain/langchain.dart';

final class FirestoreChatMessageHistory extends BaseChatMessageHistory {
  FirestoreChatMessageHistory(this.collection);

  //Firestore collection reference
  CollectionReference<Map<String, dynamic>> collection;

  @override
  Future<void> addChatMessage(ChatMessage message) async {
    print("adding message to firebase");

    FirestoreChatMessageField messageField =
        FirestoreChatMessageField(message: message);

    await collection.doc().set(messageField.toJson());
  }

  @override
  Future<void> clear() async {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessage>> getChatMessages() async {
    List<FirestoreChatMessageField> conversation = [];

    print("GET CHAT MESSAGES FROM FIRESTORE");

    var snapshot = await collection.get();

    List<Map<String, dynamic>> list =
        snapshot.docs.map((e) => e.data()).toList();

    for (var json in list) {
      conversation.add(FirestoreChatMessageField.fromJson(json));
    }

    conversation.sort();
    return conversation.map((e) => e.message).toList();
  }

  @override
  Future<ChatMessage> removeFirst() {
    throw UnimplementedError();
  }

  @override
  Future<ChatMessage> removeLast() {
    throw UnimplementedError();
  }
}

class FirestoreChatMessageField implements Comparable {
  final ChatMessage message;
  Timestamp created = Timestamp.now();

  FirestoreChatMessageField({required this.message, Timestamp? created}) {
    if (created == null) {
      this.created = Timestamp.now();
    } else {
      this.created = created;
    }
  }

  factory FirestoreChatMessageField.fromJson(Map<String, dynamic> json) {
    switch (json['message']['type']) {
      case 'SystemChatMessage':
        return FirestoreChatMessageField(
            message: SystemChatMessage.fromJson(json['message']),
            created: json['created']);
      case 'HumanChatMessage':
        return FirestoreChatMessageField(
            message: HumanChatMessage.fromJson(json['message']),
            created: json['created']);

      case 'AIChatMessage':
        return FirestoreChatMessageField(
            message: AIChatMessage.fromJson(json['message']),
            created: json['created']);

      case 'FunctionChatMessage':
        return FirestoreChatMessageField(
            message: FunctionChatMessage.fromJson(json['message']),
            created: json['created']);

      case 'CustomChatMessage':
        return FirestoreChatMessageField(
            message: CustomChatMessage.fromJson(json['message']),
            created: json['created']);
      default:
        throw FormatException("INVALID JSON FILE = ${json['type']}");
    }
  }

  Map<String, dynamic> toJson() =>
      {"message": message.toJson(), "created": created};

  @override
  int compareTo(other) {
    if (other is FirestoreChatMessageField) {
      return created.compareTo(other.created);
    } else {
      return 1;
    }
  }
}
