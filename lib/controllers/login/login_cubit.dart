import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_states.dart';

class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(LoginInitialState());
  static LoginCubit get(context) => BlocProvider.of(context);

  bool hidePassword = true;

  // تغيير حالة إظهار/إخفاء كلمة المرور
  void togglePasswordVisibility() {
    hidePassword = !hidePassword;
    emit(TogglePasswordVisibility());
  }

  // ================================
  // 🔥 تسجيل الدخول باستخدام Firebase
  // ================================
  Future<void> userLogin({
    required String email,
    required String password,
  }) async {
    emit(LoginLoadingState());

    try {
      print(email);
      print(password);

      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      FirebaseFirestore.instance.collection("users").doc(credential.user!.uid).get().then((onValue){
        if(onValue.data()==null){
          emit(LoginErrorState("المستخدم تم حذفه"));
          return;
        }

        emit(LoginSuccessState(onValue.data()!["type"]));
      });
      final deviceId = await getDeviceId();
      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "activeDevice": deviceId,
      });
    } on FirebaseAuthException catch (e) {
      String message = _firebaseErrorMessage(e.code);
      print(e.code);
      emit(LoginErrorState(message));
    } catch (e) {
      emit(LoginErrorState("حدث خطأ غير متوقع."));
    }
  }

  // ================================
  // رسائل الأخطاء بالعربي
  // ================================
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case "invalid-email":
        return "البريد الإلكتروني غير صالح.";
      case "user-disabled":
        return "تم تعطيل هذا الحساب.";
      case "user-not-found":
        return "لا يوجد حساب مرتبط بهذا البريد.";
      case "wrong-password":
        return "كلمة المرور غير صحيحة.";
      case "network-request-failed":
        return "خطأ في الاتصال. تأكد من وجود إنترنت.";
      case "too-many-requests":
        return "محاولات كثيرة. الرجاء المحاولة لاحقًا.";
      default:
        return "فشل تسجيل الدخول. حاول مرة أخرى.";
    }
  }
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // If device ID already exists → return it
    if (prefs.getString("device_id") != null) {
      return prefs.getString("device_id")!;
    }

    // Otherwise generate a new one
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString("device_id", newId);

    return newId;
  }

}
