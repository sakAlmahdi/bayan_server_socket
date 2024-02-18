import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:bayan_pos_core/data/model/socket/socket.dart';
import 'package:bayan_pos_core/data/model/socket/socket_request.dart';
import 'package:bayan_socket_server/bayan_socket_server.dart';
import 'package:get/get.dart';

class SocketEventMangment {
  // Function(BaseSocketResponse response)? setResponse;

  static lisenToServerEvents(Socket client,
      {required Future<BaseSocketResponse>? Function(BaseSocketRequest request)
          setResponse}) {
    print('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');
    List<int> buffer = [];
    client.listen((Uint8List data) async {
      var message = utf8.decode(data);
      if (!message.contains('*/d')) {
        buffer.addAll(data);
      } else {
        buffer.addAll(data);

        var message = utf8.decode(buffer);
        message = message.replaceAll('*/s', '').replaceAll('*/d', '');

        var jsonD = json.decode(message);
        print("message:$message");
        print("jsonD:$jsonD");
        inspect(message);
        inspect(jsonD);
        BaseSocketRequest baseSocketRequest = BaseSocketRequest.fromJson(jsonD);
        print("BaseSocketRequest done");
        BaseSocketResponse? response =
            await setResponse?.call(baseSocketRequest);

        // response =
        //     BaseSocketResponse(event: baseSocketRequest.event, data: "Test");

        if (response != null) {
          jsonD = json.encode(response.toJson());
          client.write(jsonD);
          client.close();
        }
        buffer.clear();
      }
    }).onDone(() async {});
  }

  // static Future<BaseSocketResponse?> getResponse(
  //     BaseSocketRequest request) async {
  //   String? event = request.event;
  //   print("event $event");
  //   return await setResponse?.call(request);
  // }

  static Future<S> initController<S>(S dependency,
      {String tag = "socket", List<Object>? dependeds}) async {
    try {
      var controller = Get.find<S>(tag: tag);
      print("object find :${S.toString()} tag :$tag");
      return controller;
    } catch (e) {
      S controller = Get.put<S>(dependency, tag: tag);
      print("object put :${S.toString()} tag :$tag");
      return controller;
    }
  }
}
