// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';

// import '../core/api/api_client.dart';
// import '../core/storage/local_storage.dart';

// class AuthProvider extends ChangeNotifier {
//   Map<String, dynamic>? user;
//   String? token;
//   bool loading = true;

//   AuthProvider() {
//     init();
//   }

//   bool get isLoggedIn => user != null && token != null;

//   Future<void> init() async {
//     try {
//       final savedUser = await LocalStorage.getUser();
//       final savedToken = await LocalStorage.getToken();

//       if (savedUser != null && savedToken != null) {
//         user = savedUser;
//         token = savedToken;
//       } else {
//         user = null;
//         token = null;
//       }
//     } catch (e) {
//       user = null;
//       token = null;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> login({
//     required String token,
//     required Map<String, dynamic> user,
//   }) async {
//     try {
//       await LocalStorage.saveToken(token);
//       await LocalStorage.saveUser(user);
//     } catch (_) {}

//     this.token = token;
//     this.user = user;
//     notifyListeners();
//   }

//   Future<void> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await ApiClient.dio.post(
//         '/auth/login',
//         data: {
//           'email': email,
//           'password': password,
//         },
//       );

//       final responseToken = response.data['token']?.toString() ?? '';
//       final responseUser =
//           Map<String, dynamic>.from(response.data['user'] ?? {});

//       if (responseToken.isEmpty || responseUser.isEmpty) {
//         throw 'Invalid login response';
//       }

//       await login(
//         token: responseToken,
//         user: responseUser,
//       );
//     } on DioException catch (e) {
//       final message =
//           e.response?.data?['error']?.toString() ??
//           e.response?.data?['message']?.toString() ??
//           'Login failed';
//       throw message;
//     } catch (e) {
//       throw e.toString();
//     }
//   }

//   Future<void> logout() async {
//     try {
//       await LocalStorage.clearAuth();
//     } finally {
//       token = null;
//       user = null;
//       notifyListeners();
//     }
//   }
// }





// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';

// import '../core/api/api_client.dart';
// import '../core/storage/local_storage.dart';

// class AuthProvider extends ChangeNotifier {
//   Map<String, dynamic>? user;
//   String? token;
//   bool loading = true;

//   AuthProvider() {
//     init();
//   }

//   bool get isLoggedIn => user != null && token != null;

//   Future<void> init() async {
//     try {
//       final savedUser = await LocalStorage.getUser();
//       final savedToken = await LocalStorage.getToken();

//       if (savedUser != null &&
//           savedToken != null &&
//           savedToken.isNotEmpty) {
//         user = savedUser;
//         token = savedToken;
//       } else {
//         user = null;
//         token = null;
//       }
//     } catch (e) {
//       user = null;
//       token = null;
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> login({
//     required String token,
//     required Map<String, dynamic> user,
//   }) async {
//     try {
//       await LocalStorage.saveToken(token);
//       await LocalStorage.saveUser(user);

//       this.token = token;
//       this.user = user;
//       notifyListeners();
//     } catch (e) {
//       throw 'Failed to save login data';
//     }
//   }

//   Future<void> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await ApiClient.dio.post(
//         '/auth/login',
//         data: {
//           'email': email,
//           'password': password,
//         },
//       );

//       final responseToken = response.data['token']?.toString() ?? '';
//       final responseUser =
//           Map<String, dynamic>.from(response.data['user'] ?? {});

//       if (responseToken.isEmpty || responseUser.isEmpty) {
//         throw 'Invalid login response';
//       }

//       await login(
//         token: responseToken,
//         user: responseUser,
//       );
//     } on DioException catch (e) {
//       final data = e.response?.data;
//       String message = 'Login failed';

//       if (data is Map) {
//         message =
//             data['error']?.toString() ??
//             data['message']?.toString() ??
//             'Login failed';
//       }

//       throw message;
//     } catch (e) {
//       throw e.toString();
//     }
//   }

//   Future<void> logout() async {
//     try {
//       await LocalStorage.clearAuth();
//     } catch (e) {
//       // ignore storage clear error, still logout locally
//     } finally {
//       token = null;
//       user = null;
//       notifyListeners();
//     }
//   }
// }






import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/storage/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  String? token;
  bool loading = true;

  AuthProvider() {
    init();
  }

  bool get isLoggedIn => user != null && token != null;

  Future<void> init() async {
    try {
      final savedUser = await LocalStorage.getUser();
      final savedToken = await LocalStorage.getToken();

      if (savedUser != null && savedToken != null && savedToken.isNotEmpty) {
        user = savedUser;
        token = savedToken;
      } else {
        user = null;
        token = null;
      }
    } catch (e) {
      user = null;
      token = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    try {
      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(user);

      this.token = token;
      this.user = user;
      notifyListeners();
    } catch (e) {
      throw 'Failed to save login data';
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseToken = response.data['token']?.toString() ?? '';
      final responseUser =
          Map<String, dynamic>.from(response.data['user'] ?? {});

      if (responseToken.isEmpty || responseUser.isEmpty) {
        throw 'Invalid login response';
      }

      await login(
        token: responseToken,
        user: responseUser,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Login failed';

      if (data is Map) {
        message =
            data['error']?.toString() ??
            data['message']?.toString() ??
            'Login failed';
      }

      throw message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> logout() async {
    try {
      await LocalStorage.clearAuth();
    } catch (e) {
      // ignore
    } finally {
      token = null;
      user = null;
      notifyListeners();
    }
  }
}