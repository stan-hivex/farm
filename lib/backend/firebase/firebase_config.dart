import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAn9ZUDuWvMG6hfMCgBOXyzfDZq8CaN9Hg",
            authDomain: "farm-lgahou.firebaseapp.com",
            projectId: "farm-lgahou",
            storageBucket: "farm-lgahou.firebasestorage.app",
            messagingSenderId: "624243276528",
            appId: "1:624243276528:web:60e67b7e0f9519ef26e035"));
  } else {
    await Firebase.initializeApp();
  }
}
