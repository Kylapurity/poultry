import 'package:fauna_pulse/screens/dashboard/dashboard_screen.dart';
import 'package:fauna_pulse/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fauna_pulse/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;

  final authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
 

  // Simulated signup function
  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    try {
      await authService.signUpWithEmailPassword(
        email,
        password,
        phoneNumber,
        username,
      );

      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Signup successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // Handle error, show message to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
      return;
    }
  }

  Future<void> _handleGoogleSignup() async {
     setState(() {
      _isLoading = true;
    });

    final googleLoginState = await authService.signInWithGoogle();

    try {
      if (mounted && (googleLoginState!=null)) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    // Get screen size to calculate dynamic spacing
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight * 0.02; // 2% of screen height

    return Scaffold(
      // Prevent resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      body: Stack(
        // Make sure the stack fills the entire screen
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'lib/assets/images/soil_background.jpg',
            fit: BoxFit.cover,
            color: Colors.white30,
            colorBlendMode: BlendMode.lighten,
          ),

          // Hexagon at top left
          Positioned(
            top: -30,
            left: -40,
            child: Image.asset(
              'lib/assets/images/hexagon_pattern.png',
              width: 150,
            ),
          ),

          // Hexagon at bottom right
          Positioned(
            bottom: -40,
            right: -50,
            child: Image.asset(
              'lib/assets/images/hexagon_pattern.png',
              width: 150,
            ),
          ),

          // Main content - only enable scrolling if really needed
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - 48, // Full height minus padding
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: spacing),

                        // Logo
                        Center(
                          child: Image.asset(
                            'lib/assets/images/fauna_pulse_logo.png',
                            width: 100,
                          ),
                        ),

                        SizedBox(height: spacing * 1.5),

                        // Signup Title
                        const Text(
                          'Sign up',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A3A3A),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 5),

                        // Subtitle
                        const Text(
                          'Enter your information',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            color: Color(0xFF5A5A5A),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 11),
                        // Gradient bar below title
                        // Container(
                        //   width: 150,
                        //   height: 3,
                        //   margin: const EdgeInsets.only(top: 16, bottom: 20),
                        //   decoration: BoxDecoration(
                        //     gradient: const LinearGradient(
                        //       colors: [
                        //         Color(0xFF5E4935),
                        //         Color(0xFF8BAF7C),
                        //       ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(10),
                        //   ),
                        // ),

                        // Signup Form with fixed spacing
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username field
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8BAF7C),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: spacing),

                              // Password field
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8BAF7C),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: spacing),

                              // Email field
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Enter your email',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8BAF7C),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: spacing),

                              // Phone Number field
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter your phone number',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E4935),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8BAF7C),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: spacing * 1.5),

                              // Get Started button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E4935),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontFamily: 'Urbanist',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),

                              // Keep the option to add Google sign in but don't display if it causes scroll
                              // Use available screen height to determine whether to show it
                              if (screenHeight > 700) ...[
                                const SizedBox(height: 16),

                                //   // Or divider
                                //   const Row(
                                //     children: [
                                //       Expanded(child: Divider(color: Colors.grey)),
                                //       Padding(
                                //         padding: EdgeInsets.symmetric(horizontal: 16),
                                //         child: Text(
                                //           'Or',
                                //           style: TextStyle(
                                //             fontFamily: 'Urbanist',
                                //             color: Colors.grey,
                                //           ),
                                //         ),
                                //       ),
                                //       Expanded(child: Divider(color: Colors.grey)),
                                //     ],
                                //   ),

                                //   const SizedBox(height: 16),

                                //   // Google sign up button
                                //   SizedBox(
                                //     width: double.infinity,
                                //     child: OutlinedButton.icon(
                                //       icon: Image.asset(
                                //         'lib/assets/icons/google_icon.png',
                                //         width: 20,
                                //         height: 20,
                                //       ),
                                //       label: const Text(
                                //         'Sign up with Google',
                                //         style: TextStyle(
                                //           fontFamily: 'Urbanist',
                                //           fontSize: 14,
                                //           fontWeight: FontWeight.bold,
                                //           color: Color(0xFF5A5A5A),
                                //         ),
                                //       ),
                                //       onPressed: _isLoading ? null : _handleGoogleSignup,
                                //       style: OutlinedButton.styleFrom(
                                //         side: const BorderSide(color: Colors.grey),
                                //         padding: const EdgeInsets.symmetric(vertical: 14),
                                //         shape: RoundedRectangleBorder(
                                //           borderRadius: BorderRadius.circular(8),
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                              ],

                              // const SizedBox(height: 16),

                              // Login link
                              Center(
                                child: TextButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const LoginScreen(),
                                              ),
                                            );
                                          },
                                  child: const Text(
                                    'Already have an account? Login',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      color: Color(0xFF5E4935),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}