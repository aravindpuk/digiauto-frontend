import 'package:digiauto/cubit/user/user_cubit.dart';
import 'package:digiauto/cubit/user/user_state.dart';
import 'package:digiauto/custom_widgets/loading_button.dart';
import 'package:digiauto/custom_widgets/scaffold_messenger.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/screens/garage.dart';
import 'package:digiauto/screens/spare_shop_register.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:digiauto/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProvider extends StatelessWidget {
  const UserProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserCubit(AuthService()),
      child: const UserRegister(),
    );
  }
}

class UserRegister extends StatefulWidget {
  const UserRegister({super.key});

  @override
  State<UserRegister> createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  userType? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final accent = theme.colorScheme.secondary;

    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserSuccess) {
          showSnackBar(context, state.message, SnackType.success);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!context.mounted) return;
            if (state.role == 'garage-admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GarageProvider()),
              );
              return;
            }
            if (state.role == 'scrap-team') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SpareShopRegisterScreen(),
                ),
              );
              return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          });
        } else if (state is UserFailure) {
          showSnackBar(context, state.message, SnackType.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 46,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/digiauto_logo.png', width: 154),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF17384C,
                                ).withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create your account',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17384C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Choose how you’ll use DigiAuto to get started.',
                                style: TextStyle(
                                  color: Color(0xFF71818B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _FieldLabel('I want to join as'),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<userType>(
                                value: _selectedRole,
                                decoration: _inputDecoration(
                                  label: 'Account type',
                                  hint: 'Select an account type',
                                  icon: Icons.badge_outlined,
                                  accent: accent,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: userType.customer,
                                    child: Text('Customer'),
                                  ),
                                  DropdownMenuItem(
                                    value: userType.garage,
                                    child: Text('Garage'),
                                  ),
                                  DropdownMenuItem(
                                    value: userType.spareShop,
                                    child: Text('Spare shop'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedRole = value),
                              ),
                              if (_selectedRole == null) ...[
                                const SizedBox(height: 7),
                                const Text(
                                  'Select an account type to continue.',
                                  style: TextStyle(
                                    color: Color(0xFF71818B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              const _FieldLabel('Your name'),
                              const SizedBox(height: 8),
                              TextField(
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: 'Full name',
                                  hint: 'Enter your name',
                                  icon: Icons.person_outline,
                                  accent: accent,
                                ),
                                onChanged: context
                                    .read<UserCubit>()
                                    .nameChanged,
                              ),
                              const SizedBox(height: 17),
                              const _FieldLabel('Mobile number'),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _inputDecoration(
                                  label: 'Mobile number',
                                  hint: 'Enter your mobile number',
                                  icon: Icons.phone_outlined,
                                  accent: accent,
                                ),
                                onChanged: context
                                    .read<UserCubit>()
                                    .mobileChanged,
                              ),
                              const SizedBox(height: 17),
                              const _FieldLabel('Create a 4-digit PIN'),
                              const SizedBox(height: 8),
                              TextField(
                                obscureText: true,
                                maxLength: 4,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _inputDecoration(
                                  label: '4-digit PIN',
                                  hint: 'Choose a PIN for future login',
                                  icon: Icons.lock_outline,
                                  accent: accent,
                                ).copyWith(counterText: ''),
                                onChanged: context.read<UserCubit>().pinChanged,
                              ),
                              const SizedBox(height: 22),
                              BlocBuilder<UserCubit, UserState>(
                                builder: (context, state) => SizedBox(
                                  width: double.infinity,
                                  child: LoadingButton(
                                    label: 'Create account',
                                    isLoading: state.isLoading,
                                    onPressed:
                                        state.isValid && _selectedRole != null
                                        ? () => context
                                              .read<UserCubit>()
                                              .registerUser(
                                                role:
                                                    _selectedRole ==
                                                        userType.garage
                                                    ? 'garage-admin'
                                                    : _selectedRole ==
                                                          userType.spareShop
                                                    ? 'scrap-team'
                                                    : 'customer',
                                              )
                                        : null,
                                    backgroundColor: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account?',
                                    style: TextStyle(color: Color(0xFF71818B)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'Log in',
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color accent,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: accent),
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF314B5B),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}
