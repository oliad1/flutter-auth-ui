import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'constants.dart';

class SignUp extends StatelessWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar('Sign In'),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          SupaEmailAuth(
            redirectTo: kIsWeb ? null : 'io.supabase.flutter://',
            onSignInComplete: (response) {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            onSignUpComplete: (response) {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          const Divider(),
          optionText,
          spacer,
          ElevatedButton.icon(
            icon: const Icon(Icons.email),
            onPressed: () {
              Navigator.popAndPushNamed(context, '/magic_link');
            },
            label: const Text('Sign in with Magic Link'),
          ),
          spacer,
          ElevatedButton.icon(
            onPressed: () {
              Navigator.popAndPushNamed(context, '/phone_sign_in');
            },
            icon: const Icon(Icons.phone),
            label: const Text('\t\t\tSign in with Phone'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(10.0, 54.0)
            ),
          ),
          spacer,
          SupaSocialsAuth(
            colored: true,
            nativeGoogleAuthConfig: const NativeGoogleAuthConfig(
              webClientId:
                  "326819364192-dnnkssj4k9udgrjdsb720jno9fto79gm.apps.googleusercontent.com",
              iosClientId:
                  "326819364192-jmk1u467hear9ee4mrct78jr6iktlree.apps.googleusercontent.com",
            ),
            enableNativeAppleAuth: true,
            socialProviders: OAuthProvider.values,
            onSuccess: (session) {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
        ],
      ),
    );
  }
}
