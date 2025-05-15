library bayan_socket_server;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bayan_pos_core/data/model/device/device.dart';
import 'package:bayan_pos_core/data/model/socket/socket.dart';
import 'package:bayan_pos_core/data/model/socket/socket_request.dart';
import 'package:bayan_pos_core/data/model/socket/socket_subscriber_Info.dart';
import 'package:bayan_socket_server/src/socket_controller.dart';
import 'package:bayan_socket_server/src/socket_event_mangment.dart';
import 'package:get/get.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf.dart' as shelf;

typedef Handler = FutureOr<shelf.Response> Function(Request request);
// typedef OnServerStop = FutureOr<bool> Function();
// typedef OnServerStart = FutureOr<bool> Function();

SocketController? controller;
Timer? _timer;

class BayanSocketServer {
  static start({
    required List<Device> allDevices,
    required String deviceId,
    String? userId,
    required Future<BaseSocketResponse>? Function(BaseSocketRequest request)
        setResponse,
    required Handler handler,
    int? port,
    Function(bool value)? serverStatus,
    Duration? keepLiveByPingDuration,
  }) {
    print("startttttttttt:");
    controller = Get.put(
        SocketController(
          allDevices: allDevices,
          deviceId: deviceId,
          userId: userId,
          setResponse: setResponse,
          port: port,
          serverStatus: serverStatus,
          keepLiveByPingDuration: keepLiveByPingDuration,
        ),
        permanent: true);
    controller?.startShelfServer(handler);
    ReceivePort receivePort = ReceivePort();

    IsolateNameServer.registerPortWithName(receivePort.sendPort, 'bayan');
    receivePort.listen((message) {
      print("${message.toString()}");
      print("stop");
      stop();
    });

    _timer = Timer(const Duration(seconds: 5), () {
      controller?.restartIfIsEmpty();
    });

    return BayanSocketServer();

    // controller.initServers();
  }

  static st(
      {required Future<BaseSocketResponse>? Function(BaseSocketRequest request)
          setResponse}) async {
    var server = await ServerSocket.bind("192.168.0.96", 12345);

    server.listen((event) {
      SocketEventMangment.lisenToServerEvents(event, setResponse: setResponse);
    });
  }

  static restart() {
    // SocketController controller = Get.find<SocketController>();
    controller?.restart();
  }

  static stop() {
    controller?.server?.close(force: true);
  }
}

List<SocketSubscriberInfo?> getIpAndProdByDeviceId(
        {required List<String> ids}) =>
    controller?.getIpAndProdByDeviceId(ids: ids) ?? [];
