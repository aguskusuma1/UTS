import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Client ID untuk Google Sign-In
  // Untuk web: WAJIB punya clientId
  // Untuk Android: Opsional, tapi bisa digunakan sebagai fallback jika oauth_client kosong di google-services.json
  // ClientId bisa didapat dari:
  // 1. Firebase Console > Project Settings > General > Web apps > OAuth client IDs
  // 2. Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client IDs
  // Format: xxxxx-xxxxx.apps.googleusercontent.com
  static const String _webClientId = '599047316506-grgfrrls68rp2ps3rcrbepib9ungc3of.apps.googleusercontent.com';
  
  // Lazy initialization untuk GoogleSignIn
  GoogleSignIn? _googleSignIn;
  
  GoogleSignIn get googleSignIn {
    if (_googleSignIn == null) {
      try {
        // Untuk Android: JANGAN gunakan clientId jika oauth_client sudah ada di google-services.json
        // Google Sign-In akan otomatis menggunakan oauth_client dari google-services.json
        // Hanya gunakan clientId untuk web (WAJIB) atau sebagai fallback jika oauth_client kosong
        final bool useClientId = kIsWeb;
        
        _googleSignIn = GoogleSignIn(
          // Pass clientId HANYA untuk web
          // Untuk Android, biarkan null agar menggunakan oauth_client dari google-services.json
          clientId: useClientId ? _webClientId : null,
          scopes: const ['email', 'profile'],
          hostedDomain: null,
        );
      } catch (e) {
        print('Error creating GoogleSignIn instance: $e');
        // Fallback: buat tanpa clientId jika ada error
        _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
        );
      }
    }
    return _googleSignIn!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Cek jika clientId belum diatur untuk web
    if (kIsWeb && (_webClientId == 'YOUR_CLIENT_ID_HERE' || _webClientId.isEmpty)) {
      throw Exception(
        'Google Sign-In Client ID belum diatur untuk web!\n\n'
        'Cara mengatur:\n'
        '1. Buka file: lib/services/auth_service.dart\n'
        '2. Ganti YOUR_CLIENT_ID_HERE dengan Client ID dari Firebase/Google Cloud Console\n'
        '3. Lihat file CARA_DAPATKAN_CLIENT_ID.md untuk panduan lengkap\n\n'
        'Atau buka: https://console.cloud.google.com/apis/credentials?project=uts-aguskusuma1'
      );
    }

    try {
      // Trigger the authentication flow dengan error handling
      GoogleSignInAccount? googleUser;
      
      // Coba sign in dengan error handling yang lebih ketat
      try {
        final signInInstance = googleSignIn;
        googleUser = await signInInstance.signIn();
      } catch (e, stackTrace) {
        // Tangkap error dari GoogleSignIn dan berikan pesan yang lebih jelas
        print('Error in googleSignIn.signIn(): $e');
        print('Stack trace: $stackTrace');
        
        // Jika error null check, berikan pesan yang lebih spesifik
        if (e.toString().contains('Null check operator') || 
            e.toString().contains('null value')) {
          throw Exception(
            'Google Sign-In error: Client ID mungkin tidak valid atau tidak dikonfigurasi dengan benar.\n\n'
            'Silakan periksa:\n'
            '1. Client ID sudah benar diatur di lib/services/auth_service.dart\n'
            '2. Client ID valid di Google Cloud Console\n'
            '3. Browser mengizinkan popup untuk Google Sign-In'
          );
        }
        
        throw Exception(
          'Gagal memulai Google Sign-In: ${e.toString()}\n\n'
          'Pastikan:\n'
          '1. Client ID sudah benar diatur\n'
          '2. Browser mengizinkan popup untuk Google Sign-In\n'
          '3. Koneksi internet stabil'
        );
      }

      // Return null if user cancelled the sign in
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        print('Error getting authentication: $e');
        throw Exception(
          'Gagal mendapatkan token autentikasi dari Google.\n\n'
          'Kemungkinan penyebab:\n'
          '1. OAuth consent screen belum dikonfigurasi dengan benar\n'
          '2. Client ID tidak memiliki izin untuk mengakses token\n'
          '3. Browser memblokir request autentikasi\n\n'
          'Error: ${e.toString()}'
        );
      }

      // Validasi bahwa idToken dan accessToken tidak null
      if (googleAuth.idToken == null) {
        String errorMessage = 'Google Sign-In failed: idToken is null\n\n';
        
        if (Platform.isAndroid) {
          errorMessage += 'Untuk Android, kemungkinan penyebab:\n'
              '1. SHA-1 fingerprint belum didaftar di Firebase Console\n'
              '2. OAuth client untuk Android belum dibuat di Firebase Console\n\n'
              'Solusi:\n'
              '1. Dapatkan SHA-1 fingerprint dengan menjalankan:\n'
              '   cd android && ./gradlew signingReport\n'
              '   atau\n'
              '   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android\n\n'
              '2. Buka Firebase Console > Project Settings > Your apps > Android app\n'
              '3. Tambahkan SHA-1 fingerprint\n'
              '4. Download ulang google-services.json\n\n'
              'Atau gunakan web client ID sebagai fallback (sudah dikonfigurasi).';
        } else if (kIsWeb) {
          errorMessage += 'Untuk Web, kemungkinan penyebab:\n'
              '1. OAuth consent screen belum dikonfigurasi\n'
              '2. Client ID tidak dikonfigurasi dengan benar\n'
              '3. Authorized JavaScript origins belum ditambahkan\n'
              '4. Authorized redirect URIs belum ditambahkan\n\n'
              'Solusi: Lihat file PENYEBAB_LOGIN_GAGAL.md untuk panduan lengkap';
        } else {
          errorMessage += 'Penyebab umum:\n'
              '1. OAuth consent screen belum dikonfigurasi\n'
              '2. Client ID tidak dikonfigurasi dengan benar\n'
              '3. Scope tidak mencukupi';
        }
        
        throw Exception(errorMessage);
      }
      if (googleAuth.accessToken == null) {
        throw Exception('Google Sign-In failed: accessToken is null');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      // Jangan rethrow, lanjutkan logout dari Firebase meskipun GoogleSignIn error
      try {
        await _auth.signOut();
      } catch (firebaseError) {
        print('Error signing out from Firebase: $firebaseError');
      }
    }
  }
}

