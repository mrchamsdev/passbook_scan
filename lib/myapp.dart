import 'package:shared_preferences/shared_preferences.dart';

class MyApp {
  static String? authTokenValue;
  static int? userId;
  static String? userName;
  static String? userEmail;

  static void setAuthToken(String? token, {int? userId, String? userName, String? userEmail}) async {
    authTokenValue = token;
    if (userId != null) {
      MyApp.userId = userId;
    }
    // Set static variables immediately (synchronously)
    if (userName != null) {
      MyApp.userName = userName;
      // Store in SharedPreferences asynchronously
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
    }
    if (userEmail != null) {
      MyApp.userEmail = userEmail;
      // Store in SharedPreferences asynchronously
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', userEmail);
    }
  }

  static Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
    userEmail = prefs.getString('userEmail');
  }

  static void clearAuthToken() async {
    authTokenValue = null;
    userId = null;
    userName = null;
    userEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  static bool get isAuthenticated {
    return authTokenValue != null && authTokenValue!.isNotEmpty;
  }
}
