import 'package:digiauto/screens/login.dart';
import 'package:digiauto/services/garage_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GarageService _service = GarageService();
  final TextEditingController _adminNameCtrl = TextEditingController();
  final TextEditingController _garageNameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _garageMobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _currentPinCtrl = TextEditingController();
  final TextEditingController _newPinCtrl = TextEditingController();
  final TextEditingController _confirmPinCtrl = TextEditingController();

  Map<String, String> _lastProfile = {};
  bool _loading = true;
  bool _editingProfile = false;
  bool _savingProfile = false;
  bool _savingPin = false;
  bool _loggingOut = false;
  bool _isError = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _garageNameCtrl.dispose();
    _mobileCtrl.dispose();
    _garageMobileCtrl.dispose();
    _emailCtrl.dispose();
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final profile = await _service.fetchProfile();
      if (!mounted) return;
      _setProfile(profile);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(_cleanError(e), isError: true);
    }
  }

  void _setProfile(Map<String, dynamic> profile) {
    _lastProfile = {
      'admin_name': (profile['admin_name'] ?? '').toString(),
      'garage_name': (profile['garage_name'] ?? '').toString(),
      'mobile': (profile['mobile'] ?? '').toString(),
      'garage_mobile': (profile['garage_mobile'] ?? '').toString(),
      'email': (profile['email'] ?? '').toString(),
    };
    _applyLastProfile();
  }

  void _applyLastProfile() {
    _adminNameCtrl.text = _lastProfile['admin_name'] ?? '';
    _garageNameCtrl.text = _lastProfile['garage_name'] ?? '';
    _mobileCtrl.text = _lastProfile['mobile'] ?? '';
    _garageMobileCtrl.text = _lastProfile['garage_mobile'] ?? '';
    _emailCtrl.text = _lastProfile['email'] ?? '';
  }

  void _toggleEditProfile() {
    setState(() {
      _editingProfile = !_editingProfile;
      _message = null;
      if (!_editingProfile) _applyLastProfile();
    });
  }

  Future<void> _updateProfile() async {
    final adminName = _adminNameCtrl.text.trim();
    final garageName = _garageNameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    if (adminName.isEmpty) {
      _showMessage("Enter admin name.", isError: true);
      return;
    }
    if (garageName.isEmpty) {
      _showMessage("Enter garage name.", isError: true);
      return;
    }
    if (mobile.isEmpty) {
      _showMessage("Enter mobile number.", isError: true);
      return;
    }

    setState(() {
      _savingProfile = true;
      _message = null;
    });

    try {
      final result = await _service.updateProfile(
        adminName: adminName,
        mobile: mobile,
        garageName: garageName,
        garageMobile: _garageMobileCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      final profile = result['profile'];
      if (profile is Map<String, dynamic>) _setProfile(profile);
      setState(() => _editingProfile = false);
      _showMessage(result['message']?.toString() ?? "Profile updated.");
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _updatePin() async {
    final currentPin = _currentPinCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirmPin = _confirmPinCtrl.text.trim();

    if (currentPin.length != 4) {
      _showMessage("Enter your current 4-digit PIN.", isError: true);
      return;
    }
    if (newPin.length != 4) {
      _showMessage("Enter a new 4-digit PIN.", isError: true);
      return;
    }
    if (newPin != confirmPin) {
      _showMessage("New PIN and confirm PIN do not match.", isError: true);
      return;
    }

    setState(() {
      _savingPin = true;
      _message = null;
    });

    try {
      final result = await _service.updateProfile(
        adminName: _lastProfile['admin_name'] ?? _adminNameCtrl.text.trim(),
        mobile: _lastProfile['mobile'] ?? _mobileCtrl.text.trim(),
        garageName: _lastProfile['garage_name'] ?? _garageNameCtrl.text.trim(),
        garageMobile:
            _lastProfile['garage_mobile'] ?? _garageMobileCtrl.text.trim(),
        email: _lastProfile['email'] ?? _emailCtrl.text.trim(),
        currentPin: currentPin,
        newPin: newPin,
      );
      _currentPinCtrl.clear();
      _newPinCtrl.clear();
      _confirmPinCtrl.clear();
      _showMessage(result['message']?.toString() ?? "PIN updated.");
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _savingPin = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _service.logout();
    } catch (_) {
      // Clear local session even if the server token is already invalid.
    }
    await clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isError = isError;
    });
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_loading)
            IconButton(
              tooltip: _editingProfile ? "Cancel edit" : "Edit profile",
              onPressed: _savingProfile ? null : _toggleEditProfile,
              icon: Icon(
                _editingProfile ? Icons.close_rounded : Icons.edit_outlined,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileHeader(theme),
                  const SizedBox(height: 16),
                  _section(
                    title: "Garage Profile",
                    action: TextButton.icon(
                      onPressed: _savingProfile ? null : _toggleEditProfile,
                      icon: Icon(
                        _editingProfile
                            ? Icons.close_rounded
                            : Icons.edit_outlined,
                        size: 18,
                      ),
                      label: Text(_editingProfile ? "Cancel" : "Edit"),
                    ),
                    children: [
                      _textField(
                        controller: _adminNameCtrl,
                        label: "Admin Name",
                        icon: Icons.person_outline,
                        readOnly: !_editingProfile,
                      ),
                      _textField(
                        controller: _garageNameCtrl,
                        label: "Garage Name",
                        icon: Icons.storefront_outlined,
                        readOnly: !_editingProfile,
                      ),
                      _textField(
                        controller: _mobileCtrl,
                        label: "Admin Mobile",
                        icon: Icons.call_outlined,
                        keyboardType: TextInputType.phone,
                        readOnly: !_editingProfile,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      _textField(
                        controller: _garageMobileCtrl,
                        label: "Garage Mobile",
                        icon: Icons.local_phone_outlined,
                        keyboardType: TextInputType.phone,
                        readOnly: !_editingProfile,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      _textField(
                        controller: _emailCtrl,
                        label: "Email",
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: !_editingProfile,
                      ),
                      if (_editingProfile)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _savingProfile
                                    ? null
                                    : _toggleEditProfile,
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _savingProfile
                                    ? null
                                    : _updateProfile,
                                icon: _savingProfile
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: Text(
                                  _savingProfile ? "Saving..." : "Save",
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: "Security",
                    children: [
                      _textField(
                        controller: _currentPinCtrl,
                        label: "Current PIN",
                        icon: Icons.lock_open_outlined,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      _textField(
                        controller: _newPinCtrl,
                        label: "New 4-Digit PIN",
                        icon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      _textField(
                        controller: _confirmPinCtrl,
                        label: "Confirm New PIN",
                        icon: Icons.verified_user_outlined,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _savingPin ? null : _updatePin,
                          icon: _savingPin
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.password_outlined),
                          label: Text(
                            _savingPin ? "Updating..." : "Update PIN",
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    _messageBox(),
                  ],
                  const SizedBox(height: 14),
                  _logoutTile(),
                ],
              ),
            ),
    );
  }

  Widget _profileHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _garageNameCtrl.text.trim().isEmpty
                      ? "Garage Profile"
                      : _garageNameCtrl.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminNameCtrl.text.trim().isEmpty
                      ? "Admin"
                      : _adminNameCtrl.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Edit profile",
            onPressed: _savingProfile ? null : _toggleEditProfile,
            icon: Icon(
              _editingProfile ? Icons.close_rounded : Icons.edit_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _messageBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isError ? const Color(0xFFFFF1F1) : const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isError ? const Color(0xFFFFC9C9) : const Color(0xFFC8EBCF),
        ),
      ),
      child: Text(
        _message!,
        style: TextStyle(
          color: _isError ? Colors.red.shade700 : Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8ED)),
      ),
      child: Row(
        children: [
          Icon(Icons.logout_outlined, color: Colors.red.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton(
            onPressed: _loggingOut ? null : _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Text(_loggingOut ? "..." : "Logout"),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLength,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          counterText: "",
          filled: true,
          fillColor: readOnly ? const Color(0xFFF7F9FB) : Colors.white,
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline, size: 18)
              : null,
        ),
      ),
    );
  }
}
