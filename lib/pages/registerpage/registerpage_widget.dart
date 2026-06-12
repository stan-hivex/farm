
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registerpage_model.dart';
export 'registerpage_model.dart';

class RegisterpageWidget extends StatefulWidget {
  const RegisterpageWidget({super.key});

  static String routeName = 'registerpage';
  static String routePath = '/registerpage';

  @override
  State<RegisterpageWidget> createState() =>
      _RegisterpageWidgetState();
}

class _RegisterpageWidgetState
    extends State<RegisterpageWidget> {
  late RegisterpageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController countryController =
      TextEditingController();

  final TextEditingController referralController =
      TextEditingController();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(
      context,
      () => RegisterpageModel(),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    countryController.dispose();
    referralController.dispose();

    _model.dispose();

    super.dispose();
  }

  InputDecoration inputDecoration(
    BuildContext context,
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: FlutterFlowTheme.of(context)
            .secondaryText,
      ),
      filled: true,
      fillColor:
          FlutterFlowTheme.of(context)
              .secondaryBackground,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 18.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color:
              FlutterFlowTheme.of(context)
                  .alternate,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color:
              FlutterFlowTheme.of(context)
                  .primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.0,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget buildLabel(
    BuildContext context,
    String text,
  ) {
    return Text(
      text,
      style:
          FlutterFlowTheme.of(context)
              .labelLarge
              .override(
                font:
                    GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FontWeight.w600,
                ),
                letterSpacing: 0.0,
                fontWeight:
                    FontWeight.w600,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager
            .instance.primaryFocus
            ?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,
        body: SingleChildScrollView(
          primary: false,
          child: Padding(
            padding:
                const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 64.0,
                        height: 64.0,
                        decoration:
                            BoxDecoration(
                          color:
                              FlutterFlowTheme.of(
                                      context)
                                  .primaryText,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      16.0),
                        ),
                        alignment:
                            const AlignmentDirectional(
                                0.0, 0.0),
                        child: SizedBox(
                          width: 40.0,
                          height: 50.0,
                          child: Stack(
                            alignment:
                                const AlignmentDirectional(
                                    -1.0,
                                    -1.0),
                            children: [
                              Align(
                                alignment:
                                    const AlignmentDirectional(
                                        0.0,
                                        0.0),
                                child:
                                    Container(
                                  width: 6.0,
                                  height:
                                      50.0,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .onPrimary,
                                    borderRadius:
                                        BorderRadius.circular(
                                            2.0),
                                  ),
                                ),
                              ),
                              Align(
                                alignment:
                                    const AlignmentDirectional(
                                        -1.0,
                                        -0.6),
                                child:
                                    Container(
                                  width:
                                      24.0,
                                  height:
                                      6.0,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .onPrimary,
                                    borderRadius:
                                        BorderRadius.circular(
                                            2.0),
                                  ),
                                ),
                              ),
                              Align(
                                alignment:
                                    const AlignmentDirectional(
                                        -1.0,
                                        0.0),
                                child:
                                    Container(
                                  width:
                                      18.0,
                                  height:
                                      6.0,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .onPrimary,
                                    borderRadius:
                                        BorderRadius.circular(
                                            2.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 16.0),

                      Text(
                        'FARM',
                        style:
                            FlutterFlowTheme.of(
                                    context)
                                .headlineMedium
                                .override(
                                  font:
                                      GoogleFonts.plusJakartaSans(
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  letterSpacing:
                                      0.0,
                                ),
                      ),

                      const SizedBox(
                          height: 4.0),

                      Text(
                        'a loop of growth',
                        style:
                            FlutterFlowTheme.of(
                                    context)
                                .labelSmall
                                .override(
                                  font:
                                      GoogleFonts.plusJakartaSans(),
                                  color:
                                      FlutterFlowTheme.of(
                                              context)
                                          .secondaryText,
                                  letterSpacing:
                                      0.0,
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 32.0),

                  Text(
                    'Create your account',
                    style:
                        FlutterFlowTheme.of(
                                context)
                            .titleLarge
                            .override(
                              font:
                                  GoogleFonts.plusJakartaSans(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                              fontWeight:
                                  FontWeight
                                      .bold,
                              letterSpacing:
                                  0.0,
                            ),
                  ),

                  const SizedBox(
                      height: 4.0),

                  Text(
                    'Secure your financial future today',
                    style:
                        FlutterFlowTheme.of(
                                context)
                            .bodyMedium
                            .override(
                              font:
                                  GoogleFonts.inter(),
                              color:
                                  FlutterFlowTheme.of(
                                          context)
                                      .secondaryText,
                              letterSpacing:
                                  0.0,
                            ),
                  ),

                  const SizedBox(
                      height: 24.0),

                  buildLabel(
                      context,
                      'First Name'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        firstNameController,
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      'Enter first name',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Last Name'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        lastNameController,
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      'Enter last name',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Username'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        usernameController,
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .isEmpty) {
                        return 'Username required';
                      }

                      if (!RegExp(
                              r'^[a-z0-9_]+$')
                          .hasMatch(
                              value)) {
                        return 'Lowercase letters, numbers and underscores only';
                      }

                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      'Enter username',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Phone Number'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        phoneController,
                    keyboardType:
                        TextInputType
                            .phone,
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .isEmpty) {
                        return 'Phone number required';
                      }

                      if (!RegExp(
                              r'^\+?[1-9]\d{7,14}$')
                          .hasMatch(
                              value)) {
                        return 'Enter valid phone number';
                      }

                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      '+254700123456',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Email'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        inputDecoration(
                      context,
                      'Enter email',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Password'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        passwordController,
                    obscureText:
                        !passwordVisible,
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .isEmpty) {
                        return 'Password required';
                      }

                      if (value
                              .length <
                          8) {
                        return 'Minimum 8 characters';
                      }

                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      'Enter password',
                    ).copyWith(
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons
                                  .visibility
                              : Icons
                                  .visibility_off,
                        ),
                        onPressed:
                            () {
                          setState(
                              () {
                            passwordVisible =
                                !passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                    context,
                    'Confirm Password',
                  ),

                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        confirmPasswordController,
                    obscureText:
                        !confirmPasswordVisible,
                    validator:
                        (value) {
                      if (value !=
                          passwordController
                              .text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration:
                        inputDecoration(
                      context,
                      'Confirm password',
                    ).copyWith(
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          confirmPasswordVisible
                              ? Icons
                                  .visibility
                              : Icons
                                  .visibility_off,
                        ),
                        onPressed:
                            () {
                          setState(
                              () {
                            confirmPasswordVisible =
                                !confirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                      context,
                      'Country'),
                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        countryController,
                    decoration:
                        inputDecoration(
                      context,
                      'Enter country',
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  buildLabel(
                    context,
                    'Referral Code',
                  ),

                  const SizedBox(
                      height: 8.0),

                  TextFormField(
                    controller:
                        referralController,
                    decoration:
                        inputDecoration(
                      context,
                      'Optional referral',
                    ),
                  ),

                  const SizedBox(
                      height: 24.0),

                  FFButtonWidget(
                    onPressed: () async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) {
    return;
  }

  final registerData = {
    "first_name": firstNameController.text.trim(),
    "last_name": lastNameController.text.trim(),
    "username": usernameController.text.trim(),
    "phone": phoneController.text.trim(),
    "email": emailController.text.trim(),
    "password": passwordController.text.trim(),
    "country": countryController.text.trim(),
    "referral_code": referralController.text.trim(),
  };

  print('REGISTER DATA');
  print(registerData);

  try {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.api}/auth/register',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(registerData),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseData['message'] ??
                'Registration successful',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(
  const Duration(seconds: 1),
  () {
    context.pushNamed(
      'otppage',
      queryParameters: {
        'phone': phoneController.text.trim(),
      },
    );
  },
);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseData['message'] ??
                'Registration failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

  } catch (e) {

    print('ERROR: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not connect to backend server',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                    text:
                        'Create Account',
                    options:
                        FFButtonOptions(
                      width:
                          double.infinity,
                      height: 54.0,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(
                        16.0,
                        0.0,
                        16.0,
                        0.0,
                      ),
                      iconPadding:
                          const EdgeInsetsDirectional.fromSTEB(
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                      ),
                      color:
                          FlutterFlowTheme.of(
                                  context)
                              .primary,
                      textStyle:
                          FlutterFlowTheme.of(
                                  context)
                              .titleSmall
                              .override(
                                font:
                                    GoogleFonts.interTight(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                                color:
                                    Colors
                                        .white,
                                letterSpacing:
                                    0.0,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                      elevation:
                          0.0,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  14.0),
                    ),
                  ),

                  const SizedBox(
                      height: 16.0),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Text(
                        'Already have an account?',
                        style:
                            FlutterFlowTheme.of(
                                    context)
                                .bodyMedium
                                .override(
                                  font:
                                      GoogleFonts.inter(),
                                  color:
                                      FlutterFlowTheme.of(
                                              context)
                                          .secondaryText,
                                  letterSpacing:
                                      0.0,
                                ),
                      ),

                      const SizedBox(
                          width: 4.0),

                      InkWell(
                        onTap: () {
                          context.pushNamed(
                              'loginpage');
                        },
                        child: Text(
                          'Login',
                          style:
                              FlutterFlowTheme.of(
                                      context)
                                  .bodyMedium
                                  .override(
                                    font:
                                        GoogleFonts.inter(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .primary,
                                    letterSpacing:
                                        0.0,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 32.0),

                  Align(
                    alignment:
                        const AlignmentDirectional(
                            0.0, 0.0),
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration:
                          BoxDecoration(
                        color:
                            FlutterFlowTheme.of(
                                    context)
                                .alternate,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    9999.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}