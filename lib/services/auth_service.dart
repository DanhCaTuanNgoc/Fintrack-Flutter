import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  GoogleSignIn _googleSignIn;

  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setString('userName', account.displayName ?? '');
        await prefs.setString('userEmail', account.email);
        await prefs.setString('userAvatar', account.photoUrl ?? '');
      }
      return account;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Ngắt hoàn toàn phiên và hủy ủy quyền tài khoản Google
    try {
      // disconnect sẽ thu hồi quyền và cũng đảm bảo trạng thái đăng xuất sạch
      await _googleSignIn.disconnect();
    } catch (_) {
      // Một số trường hợp disconnect ném lỗi nếu chưa có phiên; fallback signOut
    }
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userAvatar');

    // Tạo mới instance để xóa cache nội bộ và buộc hiển thị chọn tài khoản lại
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('Google Silent Sign-In Error: $e');
      return null;
    }
  }
}
