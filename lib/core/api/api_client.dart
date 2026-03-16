



// import 'package:dio/dio.dart';
// import '../storage/local_storage.dart';

// class ApiClient {
//   static const String baseUrl = 'http://192.168.29.79:5000/api';
//   // static const String baseUrl = 'http://localhost:5000/api';

//   static final Dio dio = Dio(
//     BaseOptions(
//       baseUrl: baseUrl,
//       connectTimeout: const Duration(seconds: 15),
//       receiveTimeout: const Duration(seconds: 15),
//       sendTimeout: const Duration(seconds: 15),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     ),
//   )
//     ..interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final token = await LocalStorage.getToken();

//           if (token != null && token.isNotEmpty) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }

//           print('REQUEST URL => ${options.baseUrl}${options.path}');
//           print('REQUEST METHOD => ${options.method}');
//           print('REQUEST DATA => ${options.data}');
//           print('REQUEST HEADERS => ${options.headers}');

//           handler.next(options);
//         },
//         onResponse: (response, handler) {
//           print('RESPONSE STATUS => ${response.statusCode}');
//           print('RESPONSE DATA => ${response.data}');
//           handler.next(response);
//         },
//         onError: (DioException err, handler) {
//           print('API ERROR TYPE => ${err.type}');
//           print('API ERROR MESSAGE => ${err.message}');
//           print('API ERROR STATUS => ${err.response?.statusCode}');
//           print('API ERROR DATA => ${err.response?.data}');
//           handler.next(err);
//         },
//       ),
//     );
// }



import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.29.79:5000/api';
  // static const String baseUrl = 'http://localhost:5000/api';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalStorage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('REQUEST URL => ${options.baseUrl}${options.path}');
          print('REQUEST METHOD => ${options.method}');
          print('REQUEST DATA => ${options.data}');
          print('REQUEST HEADERS => ${options.headers}');

          handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE STATUS => ${response.statusCode}');
          print('RESPONSE DATA => ${response.data}');
          handler.next(response);
        },
        onError: (DioException err, handler) async {
          print('API ERROR TYPE => ${err.type}');
          print('API ERROR MESSAGE => ${err.message}');
          print('API ERROR STATUS => ${err.response?.statusCode}');
          print('API ERROR DATA => ${err.response?.data}');

          if (err.response?.statusCode == 401) {
            final serverMessage =
                err.response?.data is Map && err.response?.data['message'] != null
                    ? err.response?.data['message'].toString()
                    : 'Session expired';

            handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                response: err.response,
                type: err.type,
                error: serverMessage,
                message: serverMessage,
              ),
            );
            return;
          }

          handler.next(err);
        },
      ),
    );
}