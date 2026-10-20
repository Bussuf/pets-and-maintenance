import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_calendar_service.dart';

final googleAuthProvider = StateNotifierProvider<GoogleAuthNotifier, GoogleSignInAccount?>((ref) {
  return GoogleAuthNotifier();
});

class GoogleAuthNotifier extends StateNotifier<GoogleSignInAccount?> {
  GoogleAuthNotifier() : super(null) {
    _checkInitialSignIn();
  }

  Future<void> _checkInitialSignIn() async {
    // מנסה להתחבר בשקט ברקע בעת עליית האפליקציה
    final account = await GoogleCalendarService.instance.signInSilently();
    state = account;
  }

  /// מחזיר false אם ההתחברות נכשלה. ביטול על ידי המשתמש אינו כישלון
  Future<bool> signIn() async {
    try {
      final account = await GoogleCalendarService.instance.signIn();
      state = account;
      return true;
    } catch (e) {
      print('Google sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await GoogleCalendarService.instance.signOut();
    state = null;
  }
}