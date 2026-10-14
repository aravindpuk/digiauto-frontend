import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> saveGarageId(int id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('garage_id', id);
}

Future<int?> getGarageId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('garage_id');
}

Future<void> saveBranchId(int id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('branch_id', id);
}

Future<int?> getBranchId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('branch_id');
}

Future<void> saveSpareShopId(int id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('spare_shop_id', id);
}

Future<int?> getSpareShopId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('spare_shop_id');
}

Future<void> clearSpareShopId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('spare_shop_id');
}

Future<void> saveUserRole(String role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_role', role);
}

Future<String?> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_role');
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  await prefs.remove('garage_id');
  await prefs.remove('branch_id');
  await prefs.remove('spare_shop_id');
  await prefs.remove('user_role');
}
