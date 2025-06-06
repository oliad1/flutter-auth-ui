import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_auth_ui/src/utils/constants.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:wc_form_validators/wc_form_validators.dart';

/// UI component to create a phone + password signin/ signup form
class SupaPhoneAuth extends StatefulWidget {

  /// Method to be called when the auth action is success
  final void Function(AuthResponse response) onSuccess;

  /// Method to be called when the auth action threw an excepction
  final void Function(Object error)? onError;

  /// Localization for the form
  final SupaPhoneAuthLocalization localization;

  const SupaPhoneAuth({
    super.key,
    required this.authAction,
    required this.onSuccess,
    this.onError,
    this.localization = const SupaPhoneAuthLocalization(),
  });

  @override
  State<SupaPhoneAuth> createState() => _SupaPhoneAuthState();
}

class _SupaPhoneAuthState extends State<SupaPhoneAuth> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPass = TextEditingController();

  final _formKey2 = GlobalKey<FormState>();  
  final _code = TextEditingController();

  final _formKey3 = GlobalKey<FormState>();

  bool isVerifying = false;
  var phoneNum = '';

  bool _forgotPassword = false;
  bool forgotWasPressed = false;
  bool isSigningIn = true;
  bool updatePassword = false;

  List<bool> _isObscured = [true, true, true, true, true];

  var maskFormatter = new MaskTextInputFormatter(
    mask: '+# (###) ###-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );

  var maskFormatter2 = new MaskTextInputFormatter(
            mask: '######',
            filter: { "#": RegExp(r'[0-9]') },
            type: MaskAutoCompletionType.eager
          );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (!(isVerifying) && !(updatePassword)) ...[
          if (!(_forgotPassword)) ...[
            TextFormField(
              keyboardType: TextInputType.phone,
              inputFormatters: [maskFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                } else if (!RegExp(r'^\+1 \(\d{3}\) \d{3}-\d{4}$').hasMatch(value)) {
                  return 'Invalid phone number';
                }
                return null;
              },
              decoration: const InputDecoration(
                // prefixIcon: Icon(Icons.phone),
                label: Text('Phone Number'),
              ),
              controller: _phone,
            ),

            spacer(16),

            if (!(isSigningIn)) ...[
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
                obscureText: _isObscured[0],
                controller: _password,
              ),

              spacer(16),

              TextFormField(
                validator: (value) {
                  if (value==null || value.isEmpty){
                    return "Confirm password required";
                  }
                  else if (value!=_password.text){
                    return "Passwords do not match";
                  }  
                  else {
                    return null;
                  }            
                },
                decoration: InputDecoration(
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
                controller: _confirmPass,
              ),
            ],

            if (isSigningIn) ... [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password required';
                  }
                  return null;
                },
                decoration: InputDecoration(
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
                controller: _password,
              ),
            ],
          
            spacer(16),

            ElevatedButton(
              child: Text(
                isSigningIn ? 'Sign In' : 'Sign Up',
              ),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                try {
                  if (isSigningIn) {
                    final response = await supabase.auth.signInWithPassword(
                      phone: '+'+maskFormatter.getUnmaskedText(),
                      password: _password.text,
                    );
                    widget.onSuccess(response);
                  } else {
                    final response = await supabase.auth.signUp(
                          phone: '+'+maskFormatter.getUnmaskedText(), 
                          password: _password.text,
                          data: {
                            "first_name": "",
                            "last_name": "",
                          }
                        );
                    if (!mounted) return;
                    // widget.onSuccess(response);
                    setState(() {
                      isVerifying = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Check text for SMS verification."),
                      )
                    );
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
                setState(() {
                  _phone.text = '';
                  phoneNum = '';
                  _password.text = '';
                  _confirmPass.text = '';
                });
              },
            ),

          spacer(16),

          if (isSigningIn && !(updatePassword))... [
            TextButton(
              onPressed: () {
                setState(() {
                  _forgotPassword = true;
                  forgotWasPressed = true;
                });
              },
              child: const Text('Forgot your password?'),
            ),
            TextButton(
              child: const Text(
                'Don\'t have an account? Sign up',
                // style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                    isSigningIn = !isSigningIn;
                    _forgotPassword = false;
                  });
              },
            ),
          ],

          ],

          if (!(isSigningIn)) ... [
            TextButton(
                child: const Text(
                  'Already have an account? Sign in',
                ),
                onPressed: () {
                  setState(() {
                    isSigningIn = !isSigningIn;
                    _forgotPassword = false;
                  });
                },
              ),
          ],
        ],

        if (_forgotPassword) ...[
          TextFormField(
            keyboardType: TextInputType.phone,
            inputFormatters: [maskFormatter],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              } else if (!RegExp(r'^\+1 \(\d{3}\) \d{3}-\d{4}$').hasMatch(value)) {
                return 'Invalid phone number';
              }
              return null;
            },
            decoration: const InputDecoration(
              // prefixIcon: Icon(Icons.phone),
              label: Text('Phone Number'),
            ),
            controller: _phone,
          ),

          spacer(16),

          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }
              try {
                final response = await supabase.auth.signInWithOtp(
                  phone: '+'+maskFormatter.getUnmaskedText(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Check text for SMS One-Time-Password (OTP)."),
                  )
                );
                setState(() {
                  isVerifying = true;
                  _forgotPassword = false;
                });
                // phoneNum = '+'+maskFormatter.getUnmaskedText();
                // await supabase.auth.resetPasswordForEmail(email);
                // widget.onPasswordResetEmailSent?.call();
              } on AuthException catch (error) {
                widget.onError?.call(error);
              } catch (error) {
                widget.onError?.call(error);
              }
            },
            child: const Text('Send password reset via SMS'),
          ),

          spacer(16),

          TextButton(
            onPressed: () {
              setState(() {
                _forgotPassword = false;
                forgotWasPressed = false;
              });
            },
            child: const Text('Back to Sign in'),
          ),
        ],

        if (isVerifying) ... [
          Form(
            key: _formKey2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [maskFormatter2],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the one time code sent';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    label: Text('Verification Code'),
                  ),
                  controller: _code,
                ),
                spacer(16),
                ElevatedButton(
                  child: const Text(
                    'Verify Phone',
                  ),
                  onPressed: () async {
                    if (!_formKey2.currentState!.validate()) {
                      return;
                    }
                    try {
                      final response = await supabase.auth.verifyOTP(
                        phone: '+'+maskFormatter.getUnmaskedText(),
                        token: _code.text,
                        type: OtpType.sms,
                      );
                      setState((){
                        if (forgotWasPressed){
                          updatePassword = true;
                        } else {
                          isSigningIn = true;
                          if (mounted){
                            widget.onSuccess(response);
                          }
                        }
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
                        _code.text = '';
                      });
                    }
                  },
                ),
                spacer(10),

                TextButton(
                    child: const Text(
                      'Take me back to Sign up',
                    ),
                    onPressed: () {
                      setState(() {
                        isSigningIn = false;
                        isVerifying = false;
                        //Navigator
                      });      
                    },
                  ),
              ],  
            ),
          )
        ],


        if (updatePassword) ... [
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
                    ),
                  ),
                  obscureText: _isObscured[3],
                  controller: _password,
                ),

                spacer(16),

                TextFormField(
                  validator: (value) {
                    if (value==null || value.isEmpty){
                      return "Confirm password required";
                    }
                    else if (value!=_password.text){
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
                  controller: _confirmPass,
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
                          // phone: '+'+maskFormatter.getUnmaskedText(),
                          password: _password.text,
                        )
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Password Reset!"),
                          backgroundColor: Colors.green,
                        )
                      );
                      setState(() {
                        isVerifying = false;
                        updatePassword = false;
                        isSigningIn = true;
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
                        _phone.text = '';
                        _confirmPass.text = '';
                        _password.text = '';
                      });
                    }
                  },
                ),
              ])
            )
        ]
      ])
    );
  }
}
