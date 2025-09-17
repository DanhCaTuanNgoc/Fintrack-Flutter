import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final GoogleSignIn _googleSignIn;

  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setString('userName', account.displayName ?? '');
      await prefs.setString('userEmail', account.email);
      await prefs.setString('userAvatar', account.photoUrl ?? '');
    }
    return account;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userAvatar');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }
}
