import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

  /// Yeni kullanıcı kaydı oluşturur:
  /// 1. Firebase Auth'da hesap açar
  /// 2. Go backend'e /api/users/register çağrısıyla Firestore'a belgesi yazılır
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String baseUrl,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Go backend aracılığıyla Firestore'a kullanıcı belgesi yaz
      final idToken = await credential.user!.getIdToken();
      await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: json.encode({
          'uid': credential.user!.uid,
          'email': email,
        }),
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleRegisterException(e);
    }
  }

  /// Go backend'den kullanıcı rolünü çeker (admin mi, user mı?)
  Future<String> getUserRole(String baseUrl) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return 'user';
    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['role'] ?? 'user';
      }
      return 'user';
    } catch (_) {
      return 'user';
    }
  }

  /// Hesabı tamamen siler:
  /// 1. Go backend aracılığıyla Firestore belgesini siler
  /// 2. Firebase Auth hesabını siler
  Future<void> deleteAccount(String baseUrl) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Oturum açık değil.');
    try {
      final idToken = await user.getIdToken();
      // Firestore belgesini Go backend üzerinden sil
      await http.delete(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      // Firebase Auth hesabını sil
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Hesabınızı silmek için lütfen önce çıkış yapıp tekrar giriş yapın.',
        );
      }
      throw Exception('Hesap silinirken hata oluştu: ${e.message}');
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

  /// Firebase kayıt hata mesajlarını Türkçeye çevirir
  String _handleRegisterException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      default:
        return 'Kayıt sırasında hata oluştu: ${e.message}';
    }
  }

  /// Firebase giriş hata mesajlarını Türkçeye çevirir
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

