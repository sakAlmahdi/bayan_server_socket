import 'dart:convert';
import 'dart:isolate';
import 'package:bayan_pos_core/bayan_pos_core.dart';
import 'package:shelf_plus/shelf_plus.dart';

abstract class BaseLocalApi {
  Response errorResponse(BaseSocketResponse response) {
    return Response(404, body: response.toJson());
  }

  dynamic successResponse(BaseSocketResponse response) {
    return response.toJson().removeNull();
  }

  Future<Map<String, dynamic>?> requestBody(Request request) async {
    final requestBody = await request.readAsString();
    final json = requestBody == "" ? null : jsonDecode(requestBody);
    return json;
  }

  getArgs(Request req) {
    return originalValues(req.url.queryParameters);
  }

  originalValues(Map originalMap) {
    Map<String, dynamic> convertedMap = {};

    originalMap.forEach((key, value) {
      if (value is String) {
        if (int.tryParse(value) != null) {
          convertedMap[key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          convertedMap[key] = double.parse(value);
        } else if (value.toLowerCase() == 'true' ||
            value.toLowerCase() == 'false') {
          convertedMap[key] = value.toLowerCase() == 'true';
        } else {
          convertedMap[key] = value;
        }
      } else {
        convertedMap[key] = value;
      }
    });

    return convertedMap;
  }

  String path(String path) => "/$path";
}
