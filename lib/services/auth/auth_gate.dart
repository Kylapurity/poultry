import 'package:poultry_app/screens/auth/login_screen.dart';
import 'package:poultry_app/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
 const AuthGate({super.key});

 @override
  Widget build(BuildContext context) {

    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if theres a valid session
        final session = snapshot.hasData ? snapshot.data!.session : null ;
        if(session != null){
          return DashboardScreen();
        }else{
          return LoginScreen();
        }
      }

      
      );
  }
}