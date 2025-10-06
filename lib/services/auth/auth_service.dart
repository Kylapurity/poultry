
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String phoneNumber,
    String username,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'phone_number': phoneNumber},
    );
  }

  // Sign out user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email

  String? getUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // Sign in with Google
  Future<Object?> signInWithGoogle() async {
   try {
     if (kIsWeb) {
       return await _supabase.auth.signInWithOAuth(
         OAuthProvider.google,
         redirectTo: null,
         authScreenLaunchMode: LaunchMode.platformDefault,
       );
     } else {
       const webClientId = '968801481308-bmpep7j70crkh4sd6lgb66af98srflkn.apps.googleusercontent.com';
       const iosClientId = '968801481308-ln55vs90talorbk6tc50f4880ukgnd11.apps.googleusercontent.com'; 
       const androidClientId = '968801481308-j74eu9tsouj18m69moqm6cbvp5tmaq3c.apps.googleusercontent.com';
       
       final GoogleSignIn googleSignIn = GoogleSignIn(
         clientId: Platform.isIOS ? iosClientId : androidClientId,
         serverClientId: webClientId,
       );
       
       final googleUser = await googleSignIn.signIn();
       if (googleUser == null) return null;
       
       final googleAuth = await googleUser.authentication;
       final accessToken = googleAuth.accessToken;
       final idToken = googleAuth.idToken;
       
       if (accessToken == null) throw 'No Access Token found.';
       if (idToken == null) throw 'No ID Token found.';
       
       return await _supabase.auth.signInWithIdToken(
         provider: OAuthProvider.google,
         idToken: idToken,
         accessToken: accessToken,
       );
     }
   } catch (e) {
     throw Exception('Google sign in failed: $e');
   }
 }

 

  // Sign out
}
