import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Uses `toFirestore()` to store user data properly
  Future<void> addUser(UserModel user) async {
    await _firestore.collection('users').doc(user.userId).set(user.toFirestore());
  }

  /// ✅ Fetch user and convert Firestore data into `UserModel`
  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }
}
