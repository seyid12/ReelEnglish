import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// E-posta ve şifre ile giriş yapar
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Uygulamadan çıkış yapar
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Çıkış yaparken hata oluştu: $e');
    }
  }

  /// Mevcut kullanıcıyı döner
  User? get currentUser => _firebaseAuth.currentUser;

  /// Mevcut kullanıcı durumunu stream olarak döner
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Firebase hata mesajlarını Türkçeye çevirir
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlıştır. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'E-posta/şifre giriş işlemi devre dışı bırakılmış.';
      default:
        return 'Giriş sırasında hata oluştu: ${e.message}';
    }
  }
}
