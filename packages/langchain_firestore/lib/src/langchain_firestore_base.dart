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
    var snapshot = await collection.get();

    //Delete all docs in firestore
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages() async {
    //Get chat messages in ascending order so the newest message is the last in the list
    var snapshot = await collection.orderBy("created", descending: false).get();

    //Take each doc and add it to the conversation list.
    List<FirestoreChatMessageField> conversation = snapshot.docs.map((doc) {
      return FirestoreChatMessageField.fromJson(doc.data());
    }).toList();

    return conversation.map((e) => e.message).toList();
  }

  /// Removes and returns the first (oldest) element of the history.
  ///
  /// The history must not be empty when this method is called.
  @override
  Future<ChatMessage> removeFirst() async {
    var snapshot =
        await collection.orderBy("created", descending: false).limit(1).get();

    //get oldest document
    var oldest = snapshot.docs.first;

    //Delete doc in firestore
    oldest.reference.delete();

    //Create FirestoreChatMessageField and return ChatMessage
    return FirestoreChatMessageField.fromJson(oldest.data()).message;
  }

  /// Removes and returns the last (newest) element of the history.
  ///
  /// The history must not be empty when this method is called.
  @override
  Future<ChatMessage> removeLast() async {
    var snapshot =
        await collection.orderBy("created", descending: true).limit(1).get();

    //get newest document
    var newest = snapshot.docs.first;

    //Delete doc in firestore
    newest.reference.delete();

    //Create FirestoreChatMessageField and return ChatMessage
    return FirestoreChatMessageField.fromJson(newest.data()).message;
  }
}

class FirestoreChatMessageField {
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
      case '${SystemChatMessage.defaultPrefix}ChatMessage':
        return FirestoreChatMessageField(
            message: SystemChatMessage.fromJson(json['message']),
            created: json['created']);
      case '${HumanChatMessage.defaultPrefix}ChatMessage':
        return FirestoreChatMessageField(
            message: HumanChatMessage.fromJson(json['message']),
            created: json['created']);

      case '${AIChatMessage.defaultPrefix}ChatMessage':
        return FirestoreChatMessageField(
            message: AIChatMessage.fromJson(json['message']),
            created: json['created']);

      case '${FunctionChatMessage.defaultPrefix}ChatMessage':
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
}
