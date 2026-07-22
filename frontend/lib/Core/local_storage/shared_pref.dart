import 'package:shared_preferences/shared_preferences.dart';

class LocalStoragePref {
  static late SharedPreferences pref;

  static Future<void> initLocalStoragePref() async {
    pref = await SharedPreferences.getInstance();
  }

  static Future<void> setSiblingStudentId(int id) async {
    await pref.setInt('siblingStudentId', id);
  }

  static Future<int?> getSiblingStudentId() async {
    return pref.getInt('siblingStudentId');
  }
}
