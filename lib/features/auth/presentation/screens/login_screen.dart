import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _empIdCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _empIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          employeeId: _empIdCtrl.text,
          password:   _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Route based on role
            final role = state.authResponse.user.role;
            if (role == 'ADMIN') {
              context.go(AppConstants.routeAdminHome);
            } else {
              context.go(AppConstants.routeWorkerHome);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand header
                          const AuthBrandHeader(
                            title: 'SiteTracker',
                            subtitle: 'Manage your construction sites',
                          ),

                          const SizedBox(height: 40),

                          // Login card
                          AuthCard(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Welcome back',
                                        style: AppTheme.headlineMedium),
                                    const SizedBox(height: 4),
                                    Text('Sign in to your account',
                                        style: AppTheme.bodyMedium),

                                    const SizedBox(height: 28),

                                    // Employee ID field
                                    AuthTextField(
                                      controller:    _empIdCtrl,
                                      label:         'Employee ID',
                                      hint:          'e.g. EMP001',
                                      prefixIcon:    Icons.badge_outlined,
                                      keyboardType:  TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Employee ID is required';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Password field
                                    AuthTextField(
                                      controller:      _passwordCtrl,
                                      label:           'Password',
                                      hint:            'Enter your password',
                                      prefixIcon:      Icons.lock_outline_rounded,
                                      isPassword:      true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (v.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 28),

                                    // Login button
                                    AuthPrimaryButton(
                                      label:     'Sign In',
                                      isLoading: isLoading,
                                      onPressed: isLoading ? null : _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider with text
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppTheme.divider, thickness: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('New here?', style: AppTheme.bodyMedium),
                              ),
                              const Expanded(
                                child: Divider(color: AppTheme.divider, thickness: 1),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Register button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(AppConstants.routeSignup),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                    color: AppTheme.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Create Account',
                                style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Text(
                            '© 2025 SiteTracker. All rights reserved.',
                            style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
