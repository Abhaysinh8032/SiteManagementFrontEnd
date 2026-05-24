import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _empIdCtrl    = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  String _selectedRole = 'WORKER'; // default

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignupRequested(
          employeeId:  _empIdCtrl.text,
          name:        _nameCtrl.text,
          password:    _passwordCtrl.text,
          role:        _selectedRole,
          phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final role = state.authResponse.user.role;
            context.go(role == 'ADMIN'
                ? AppConstants.routeAdminHome
                : AppConstants.routeWorkerHome);
          } else if (state is AuthPendingApproval) {
            _showPendingDialog();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Container(
            decoration:
                const BoxDecoration(gradient: AppTheme.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Back button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.textPrimary),
                        ),
                        Text('Back to Login',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.primary)),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              // Header
                              const AuthBrandHeader(
                                title: 'Join SiteTracker',
                                subtitle: 'Create your account to get started',
                              ),

                              const SizedBox(height: 32),

                              // Form card
                              AuthCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Create Account',
                                            style: AppTheme.headlineMedium),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Fill in your details to register',
                                            style: AppTheme.bodyMedium),
                                        const SizedBox(height: 24),

                                        // Employee ID
                                        AuthTextField(
                                          controller:  _empIdCtrl,
                                          label:       'Employee ID',
                                          hint:        'e.g. EMP002',
                                          prefixIcon:  Icons.badge_outlined,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Employee ID is required';
                                            }
                                            if (v.trim().length < 3) {
                                              return 'Minimum 3 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Full Name
                                        AuthTextField(
                                          controller: _nameCtrl,
                                          label:      'Full Name',
                                          hint:       'e.g. Abhay Kumar',
                                          prefixIcon: Icons.person_outline_rounded,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Name is required';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Phone (optional)
                                        AuthTextField(
                                          controller:   _phoneCtrl,
                                          label:        'Phone Number (optional)',
                                          hint:         'e.g. 9876543210',
                                          prefixIcon:   Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 14),

                                        // Password
                                        AuthTextField(
                                          controller:  _passwordCtrl,
                                          label:       'Password',
                                          hint:        'Minimum 6 characters',
                                          prefixIcon:  Icons.lock_outline_rounded,
                                          isPassword:  true,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Password is required';
                                            }
                                            if (v.length < 6) {
                                              return 'Minimum 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Confirm Password
                                        AuthTextField(
                                          controller:      _confirmCtrl,
                                          label:           'Confirm Password',
                                          hint:            'Re-enter password',
                                          prefixIcon:      Icons.lock_outline_rounded,
                                          isPassword:      true,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          validator: (v) {
                                            if (v != _passwordCtrl.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),

                                        // Role picker
                                        Text('Role',
                                            style: AppTheme.bodyMedium
                                                .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary)),
                                        const SizedBox(height: 10),
                                        _RolePicker(
                                          selected: _selectedRole,
                                          onChanged: (r) =>
                                              setState(() => _selectedRole = r),
                                        ),

                                        const SizedBox(height: 28),

                                        // Submit
                                        AuthPrimaryButton(
                                          label:     'Create Account',
                                          isLoading: isLoading,
                                          onPressed: isLoading ? null : _submit,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_empty_rounded,
                  color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Account Pending'),
          ],
        ),
        content: const Text(
          'Your account has been created and is awaiting approval from a supervisor.\n\n'
          'You will be able to log in once your account is approved.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppConstants.routeLogin);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role picker widget
// ─────────────────────────────────────────────────────────────────────────────

class _RolePicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _RolePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _RoleTile(
          role:       'WORKER',
          label:      'Worker',
          icon:       Icons.engineering_outlined,
          isSelected: selected == 'WORKER',
          onTap:      () => onChanged('WORKER'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _RoleTile(
          role:       'ADMIN',
          label:      'Admin / Supervisor',
          icon:       Icons.manage_accounts_outlined,
          isSelected: selected == 'ADMIN',
          onTap:      () => onChanged('ADMIN'),
        )),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : AppTheme.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    isSelected ? AppTheme.primary : AppTheme.textHint,
                size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
