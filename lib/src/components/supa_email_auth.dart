import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_auth_ui/src/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'globals.dart' as globals;
import 'package:wc_form_validators/wc_form_validators.dart';

/// Information about the metadata to pass to the signup form
///
/// You can use this object to create additional fields that will be passed to the metadata of the user upon signup.
/// For example, in order to create additional `username` field, you can use the following:
/// ```dart
/// MetaDataField(label: 'Username', key: 'username')
/// ```
///
/// Which will update the user's metadata in like the following:
///
/// ```dart
/// { 'username': 'Whatever your user entered' }
/// ```
class MetaDataField {
  /// Put Fields in a row
  // final bool inRow;

  /// Label of the `TextFormField` for this metadata
  final String label;

  /// Key to be used when sending the metadata to Supabase
  final String key;

  /// Validator function for the metadata field
  final String? Function(String?)? validator;

  /// Icon to show as the prefix icon in TextFormField
  final Icon? prefixIcon;

  MetaDataField({
    required this.label,
    required this.key,
    this.validator,
    this.prefixIcon,
    // required this.inRow,
  });
}

/// {@template supa_email_auth}
/// UI component to create email and password signup/ signin form
///
/// ```dart
/// SupaEmailAuth(
///   onSignInComplete: (response) {
///     // handle sign in complete here
///   },
///   onSignUpComplete: (response) {
///     // handle sign up complete here
///   },
/// ),
/// ```
/// /// {@endtemplate}
class SupaEmailAuth extends StatefulWidget {
  /// The URL to redirect the user to when clicking on the link on the
  /// confirmation link after signing up.
  final String? redirectTo;

  /// Callback for the user to complete a sign in.
  final void Function(AuthResponse response) onSignInComplete;

  /// Callback for the user to complete a signUp.
  ///
  /// If email confirmation is turned on, the user is
  final void Function(AuthResponse response) onSignUpComplete;

  /// Callback for sending the password reset email
  final void Function()? onPasswordResetEmailSent;

  /// Callback for when the auth action threw an excepction
  ///
  /// If set to `null`, a snack bar with error color will show up.
  final void Function(Object error)? onError;

  final List<MetaDataField>? metadataFields;

  /// {@macro supa_email_auth}
  const SupaEmailAuth({
    Key? key,
    this.redirectTo,
    required this.onSignInComplete,
    required this.onSignUpComplete,
    this.onPasswordResetEmailSent,
    this.onError,
    this.metadataFields,
  }) : super(key: key);

  @override
  State<SupaEmailAuth> createState() => _SupaEmailAuthState();
}

class _SupaEmailAuthState extends State<SupaEmailAuth> {
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _codeController = TextEditingController();
  late final Map<MetaDataField, TextEditingController> _metadataControllers;

  bool _isLoading = false;

  List<bool> _isObscured = [true, true, true, true, true];

  bool isVerifying = false;

  /// The user has pressed forgot password button
  bool _forgotPassword = false;

  bool _isSigningIn = true;

  var maskFormatter = new MaskTextInputFormatter(
    mask: '######',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.eager
  );

  @override
  void initState() {
    super.initState();
    _metadataControllers = Map.fromEntries((widget.metadataFields ?? []).map(
        (metadataField) => MapEntry(metadataField, TextEditingController())));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _codeController.dispose();
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!(isVerifying) && !(globals.updatePassword)) ... [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !EmailValidator.validate(_emailController.text)) {
                    return 'Invalid email address';
                  }
                  else {
                    return null;
                  }
                },
                decoration: const InputDecoration(
                  label: Text('Email'),
                ),
                controller: _emailController,
              ),

              if (!_forgotPassword) ...[
                spacer(16),
                if (!_isSigningIn) ...[
                  TextFormField(
                    validator:Validators.compose([
                        Validators.required('Password is required'),
                        Validators.patternString(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$', 'Password must have:\n\t•\t1 Uppercase\n\t•\t1 Lowercase\n\t•\t1 Number\n\t•\t8 Characters Long')]),
                    decoration: InputDecoration(
                      // prefixIcon: Icon(Icons.key_rounded),
                      label: Text('Password'),
                      suffixIcon: IconButton(
                        icon: _isObscured[0] ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                        onPressed: () { 
                          setState((){
                            _isObscured[0] = !_isObscured[0];
                          });
                        },
                      )
                    ),
                    autofillHints: [AutofillHints.password],
                    obscureText: _isObscured[0],
                    controller: _passwordController,
                  ),

                  spacer(16),
                  
                  TextFormField(
                    validator: (value) {
                      if (value==null || value.isEmpty){
                        return "Confirm password required.";
                      }
                      else if (value!=_passwordController.text){
                        return "Passwords do not match.";
                      }  
                      else {
                        return null;
                      }            
                    },
                    decoration: InputDecoration(
                      // prefixIcon: Icon(Icons.key_rounded),
                      label: Text('Confirm Password'),
                      suffixIcon: IconButton(
                        icon: _isObscured[1] ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                        onPressed: () { 
                          setState((){
                            _isObscured[1] = !_isObscured[1];
                          });
                        },
                      )
                    ),
                    obscureText: _isObscured[1],
                    controller: _confirmPassController,
                  ),
                ],

                if(_isSigningIn) ... [
                  TextFormField(
                    validator: 
                    (value) {
                      if (value==null || value.isEmpty){
                        return "Password required.";
                      }
                      else {
                        return null;
                      }
                    },
                    autofillHints: [AutofillHints.password],
                    onEditingComplete: ()=> TextInput.finishAutofillContext(),
                    decoration: InputDecoration(
                      // prefixIcon: Icon(Icons.key_rounded),
                      label: Text('Password'),
                      suffixIcon: IconButton(
                        icon: _isObscured[2] ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                        onPressed: () { 
                          setState((){
                            _isObscured[2] = !_isObscured[2];
                          });
                        },
                      )
                    ),
                    obscureText: _isObscured[2],
                    controller: _passwordController,
                  )
                ],

                spacer(16),

                ElevatedButton(
                  child: (_isLoading)
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 1.5,
                          ),
                        )
                      : Text(_isSigningIn ? 'Sign In' : 'Sign Up'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    setState(() {
                      // _isLoading = true;
                    });
                    try {
                      if (_isSigningIn) {
                        final response = await supabase.auth.signInWithPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        widget.onSignInComplete.call(response);
                      } else {
                        final response = await supabase.auth.signUp(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          emailRedirectTo: widget.redirectTo,
                          data: {
                            "first_name": "", // Empty string as default value for firstName
                            "last_name": "", // Empty string as default value for lastName
                            // "userType": null, // Null as default value for userType
                            // "cardConnected": false, // False as default value for cardConnected
                          },
                          // data: widget.metadataFields == null
                          //     ? null
                          //     : _metadataControllers.map<String, dynamic>(
                          //         (metaDataField, controller) =>
                          //             MapEntry(metaDataField.key, controller.text)),
                        );
                        widget.onSignUpComplete.call(response);
                      }
                    } on AuthException catch (error) {
                      if (widget.onError == null) {
                        context.showErrorSnackBar(error.message);
                      } else {
                        widget.onError?.call(error);
                      }
                    } catch (error) {
                      if (widget.onError == null) {
                        context.showErrorSnackBar(
                            'Unexpected error has occurred: $error');
                      } else {
                        widget.onError?.call(error);
                      }
                    }
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),

                spacer(16),

                if (_isSigningIn) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = false;
                        _forgotPassword = true;
                      });
                    },
                    child: const Text('Forgot your password?'),
                  ),
                ],

                TextButton(
                  key: const ValueKey('toggleSignInButton'),
                  onPressed: () {
                    setState(() {
                      _isLoading = false;
                      _forgotPassword = false;
                      _isSigningIn = !_isSigningIn;
                    });
                  },
                  child: Text(_isSigningIn
                      ? 'Don\'t have an account? Sign up'
                      : 'Already have an account? Sign in'),
                ),
              ],

              if (_forgotPassword) ...[
                spacer(16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      setState(() {
                        _isLoading = true;
                      });
                      // await supabase.auth.resetPasswordForEmail(email);
                        await supabase.auth.signInWithOtp(
                          email: _emailController.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Check text for SMS One-Time-Password (OTP)."),
                          )
                        );
                        setState(() {
                          isVerifying = true;
                          globals.updatePassword = false;
                          _forgotPassword = false;
                        });
                        // widget.onPasswordResetEmailSent?.call();
                      } on AuthException catch (error) {
                        widget.onError?.call(error);
                      } catch (error) {
                        widget.onError?.call(error);
                      }
                  },
                  child: const Text('Send password reset email'),
                ),

                spacer(16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSigningIn = true;
                      _isLoading = false;
                      _forgotPassword = false;
                    });
                  },
                  child: const Text('Back to Sign in'),
                ),
              ],
            ],

            if (isVerifying) ... [
              Form(
                key: _formKey2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskFormatter],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the one time code sent';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        label: Text('Verification Code'),
                      ),
                      controller: _codeController,
                    ),
                    spacer(16),
                    ElevatedButton(
                      child: const Text(
                        'Verify OTP',
                      ),
                      onPressed: () async {
                        if (!_formKey2.currentState!.validate()) {
                          return;
                        }
                        try {
                          final response = await supabase.auth.verifyOTP(
                            email: _emailController.text,
                            token: _codeController.text,
                            type: OtpType.email,
                          );
                          setState((){
                            globals.updatePassword = true;
                            isVerifying = false;
                          });
                          // widget.onSuccess(response);
                        } on AuthException catch (error) {
                          if (widget.onError == null) {
                            context.showErrorSnackBar(error.message);
                          } else {
                            widget.onError?.call(error);
                          }
                        } catch (error) {
                          if (widget.onError == null) {
                            context.showErrorSnackBar(
                                'Unexpected error has occurred: $error');
                          } else {
                            widget.onError?.call(error);
                          }
                        }
                        if (mounted) {
                          setState(() {
                            _codeController.text = '';
                          });
                        }
                      },
                    ),
                    spacer(10),

                    TextButton(
                        child: const Text(
                          'Take me back to Sign in',
                        ),
                        onPressed: () {
                          setState(() {
                            _isSigningIn = true;
                            _isLoading = false;
                            isVerifying = false;
                            //Navigator
                          });      
                        },
                      ),
                  ]),
              )
            ],

            if (globals.updatePassword) ... [
              Form(
                key: _formKey3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      validator:Validators.compose([
                          Validators.required('Password is required'),
                          Validators.patternString(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$', 'Password must have:\n\t•\t1 Uppercase\n\t•\t1 Lowercase\n\t•\t1 Number\n\t•\t8 Characters Long')]),
                      decoration: InputDecoration(
                        // prefixIcon: Icon(Icons.key_rounded),
                        label: Text('New Password'),
                        suffixIcon: IconButton(
                          icon: _isObscured[3] ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                          onPressed: () { 
                            setState((){
                              _isObscured[3] = !_isObscured[3];
                            });
                          },
                        )
                      ),
                      obscureText: _isObscured[3],
                      controller: _passwordController,
                    ),

                    spacer(16),

                    TextFormField(
                      validator: (value) {
                        if (value==null || value.isEmpty){
                          return "Confirm password required";
                        }
                        else if (value!=_passwordController.text){
                          return "Passwords do not match";
                        }  
                        else {
                          return null;
                        }            
                      },
                      decoration: InputDecoration(
                        label: Text('Confirm New Password'),
                        suffixIcon: IconButton(
                          icon: _isObscured[4] ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                          onPressed: () { 
                            setState((){
                              _isObscured[4] = !_isObscured[4];
                            });
                          },
                        )
                      ),
                      obscureText: _isObscured[4],
                      controller: _confirmPassController,
                    ),
                    spacer(16),

                    ElevatedButton(
                      child: const Text(
                        'Update Password',
                      ),
                      onPressed: () async {
                        if (!_formKey3.currentState!.validate()) {
                          return;
                        }
                        try {
                          final response = await supabase.auth.updateUser(
                            UserAttributes(
                              email: _emailController.text,
                              password: _passwordController.text,
                            )
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Password Reset!"),
                              backgroundColor: Colors.green,
                            )
                          );
                          setState(() {
                            globals.updatePassword = false;
                            _isSigningIn = true;
                          });
                        } on AuthException catch (error) {
                          if (widget.onError == null) {
                            context.showErrorSnackBar(error.message);
                          } else {
                            widget.onError?.call(error);
                          }
                        } catch (error) {
                          if (widget.onError == null) {
                            context.showErrorSnackBar(
                                'Unexpected error has occurred: $error');
                          } else {
                            widget.onError?.call(error);
                          }
                        }
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _emailController.text = '';
                            _confirmPassController.text = '';
                            _passwordController.text = '';
                          });
                        }
                      },
                    ),
                  ])
                )
            ]
          ]
        )
      ),
    );
  }
}
