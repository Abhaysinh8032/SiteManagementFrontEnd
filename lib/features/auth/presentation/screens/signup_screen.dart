import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _empIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _role = 'WORKER';
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSignupRequested(
        employeeId: _empIdCtrl.text,
        name: _nameCtrl.text,
        password: _passCtrl.text,
        role: _role,
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(
              '${AppConstants.routeHome}?role=${state.authResponse.user.role}',
            );
          } else if (state is AuthPendingApproval) {
            _showPendingDialog();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Back to Login',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              const AuthBrandHeader(
                                title: 'Join SiteTracker',
                                subtitle: 'Create your account to get started',
                              ),
                              const SizedBox(height: 32),
                              AuthCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: AppTheme.headlineMedium,
                                        ),
                                        const SizedBox(height: 24),
                                        AuthTextField(
                                          controller: _empIdCtrl,
                                          label: 'Employee ID',
                                          hint: 'e.g. EMP002',
                                          prefixIcon: Icons.badge_outlined,
                                          validator: (v) =>
                                              (v == null || v.trim().length < 3)
                                              ? 'Minimum 3 characters'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        AuthTextField(
                                          controller: _nameCtrl,
                                          label: 'Full Name',
                                          hint: 'e.g. Abhay Kumar',
                                          prefixIcon:
                                              Icons.person_outline_rounded,
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? 'Name is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        AuthTextField(
                                          controller: _phoneCtrl,
                                          label: 'Phone (optional)',
                                          hint: 'e.g. 9876543210',
                                          prefixIcon: Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 14),
                                        AuthTextField(
                                          controller: _passCtrl,
                                          label: 'Password',
                                          hint: 'Minimum 6 characters',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          isPassword: true,
                                          validator: (v) =>
                                              (v == null || v.length < 6)
                                              ? 'Minimum 6 characters'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        AuthTextField(
                                          controller: _confirmCtrl,
                                          label: 'Confirm Password',
                                          hint: 'Re-enter password',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          isPassword: true,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          validator: (v) => v != _passCtrl.text
                                              ? 'Passwords do not match'
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Role',
                                          style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _RoleTile(
                                                role: 'WORKER',
                                                label: 'Worker',
                                                icon:
                                                    Icons.engineering_outlined,
                                                isSelected: _role == 'WORKER',
                                                onTap: () => setState(
                                                  () => _role = 'WORKER',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _RoleTile(
                                                role: 'ADMIN',
                                                label: 'Admin / Supervisor',
                                                icon: Icons
                                                    .manage_accounts_outlined,
                                                isSelected: _role == 'ADMIN',
                                                onTap: () => setState(
                                                  () => _role = 'ADMIN',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        AuthPrimaryButton(
                                          label: 'Create Account',
                                          isLoading: loading,
                                          onPressed: loading ? null : _submit,
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
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
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
        Expanded(
          child: _RoleTile(
            role: 'WORKER',
            label: 'Worker',
            icon: Icons.engineering_outlined,
            isSelected: selected == 'WORKER',
            onTap: () => onChanged('WORKER'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleTile(
            role: 'ADMIN',
            label: 'Admin / Supervisor',
            icon: Icons.manage_accounts_outlined,
            isSelected: selected == 'ADMIN',
            onTap: () => onChanged('ADMIN'),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role, label;
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
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
