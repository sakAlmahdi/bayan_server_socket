import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:bayan_pos_core/data/model/device/device.dart';
import 'package:bayan_pos_core/data/model/socket/socket.dart';
import 'package:bayan_pos_core/data/model/socket/socket_request.dart';
import 'package:bayan_socket_server/core/halpers/base_network_helper.dart';
import 'package:bayan_socket_server/src/socket_event_mangment.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nsd/nsd.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:bayan_pos_core/data/model/socket/socket_subscriber_Info.dart';

class SocketController extends GetxController {
  SocketController({
    required this.allDevices,
    required this.deviceId,
    this.userId,
    this.port,
    required this.setResponse,
    this.serverStatus,
    this.keepLiveByPingDuration,
  });
  int? port;
  bool isStartMaster = false;
  final networkService = Get.put(BaseNetworkHelper(), permanent: true);
  ServerSocket? masterServer;
  SocketSubscriberInfo? masterSubscriberInfo;
  Discovery? discovery;
  // ActivationController activationController = Get.find<ActivationController>();
  final isMasterOnline = false.obs;
  Registration? registration;
  NetworkInfo infoNetwork = NetworkInfo();

  final networkName = "".obs;
  Device? masterDev;
  SocketSubscriberInfo? masterServerSubscriberInfo;

  late List<Device> allDevices;
  late String deviceId;

  String? userId;
  bool isStartMeServer = false;
  Future<BaseSocketResponse>? Function(BaseSocketRequest request) setResponse;
  List<String> connectedIps = [];

  Map<String, SocketSubscriberInfo> subscriptions = {};

  HttpServer? server;
  Handler? handler;

  Function(bool value)? serverStatus;

  Duration? keepLiveByPingDuration;

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  startShelfServer(Handler handler) {
    this.handler = handler;
    makeMeServerOnShelf();
    ever(networkService.isHasConnectionToNetwork, (callback) async {
      if (callback == true) {
        serverStatus?.call(true);
        await makeMeServerOnShelf();
      } else {
        serverStatus?.call(false);
        await server?.close();
        await unsubscripToNSD();
      }
    });
  }

  // makeMeServerOnShelf() async {
  //   print("createIpAndPort");
  //   await createIpAndPort();
  //   print("listenToNSD");
  //   try {
  //     await listenToNSD();
  //   } catch (e) {
  //     print(e.toString());
  //   }
  //   print("subscripToNSD");
  //   try {
  //     await subscripToNSD();
  //   } catch (e) {}
  //   print("server");
  //   // if (server.)
  //   try {
  //     // await server?.close();
  //     // var handler =
  //     //     const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

  //     server = await shelf_io.serve(
  //       handler!.call,
  //       masterServerSubscriberInfo!.ip!,
  //       masterServerSubscriberInfo!.port!,
  //       // 0,
  //       shared: true,
  //     );

  //     masterServerSubscriberInfo?.port = server?.port;
  //     server?.autoCompress = true;

  //     server?.idleTimeout = null;
  //     server?.sessionTimeout = 86400 * 30;

  //     if (server != null) return;

  //     // Enable content compression

  //     print('Serving at http://${server?.address.host}:${server?.port}');
  //   } catch (e) {
  //     print("BAYAN ERROR : ${e.toString()}");
  //   }
  // }
  makeMeServerOnShelf() async {
    print("🛠 createIpAndPort");
    await createIpAndPort();

    print("🔍 listenToNSD");
    try {
      await listenToNSD();
    } catch (e) {
      print("❌ NSD Listen Error: $e");
    }

    print("📡 subscripToNSD");
    try {
      await subscripToNSD();
    } catch (e) {
      print("❌ NSD Subscription Error: $e");
    }

    print("🚀 Starting Shelf Server...");

    try {
      // إغلاق السيرفر القديم إذا موجود
      await server?.close(force: true);

      // تشغيل السيرفر
      server = await shelf_io.serve(
        handler!.call,
        masterServerSubscriberInfo!.ip!,
        masterServerSubscriberInfo!.port!,
        shared: true,
      );

      // تفعيل إعدادات السيرفر
      server!.autoCompress = true;
      server!.idleTimeout = null; // ❗️مهم جدًا - يمنع انقطاع السيرفر بعد الخمول
      // server!.sessionTimeout = 86400 * 30; // جلسة طويلة جدًا

      masterServerSubscriberInfo?.port = server?.port;

      print(
          '✅ Server running at http://${server!.address.host}:${server!.port}');
    } catch (e) {
      print("❌ Server Startup Error: $e");
    }

    // لوج دوري للتأكد أن السيرفر حي
    Timer.periodic(Duration(minutes: 1), (_) {
      print("✅ Server heartbeat: ${DateTime.now()}");
    });
  }

  shelf.Response _echoRequest(Request request) =>
      shelf.Response.ok('Request for "${request.url}"');

  start() async {
    await createIpAndPort();
    await listenToNSD();
    await createMasterServer(ref: true);
    await subscripToNSD();

    // re start socket
    ever(networkService.isHasConnectionToNetwork, (callback) async {
      if (callback == true) {
        await restart();
      } else {
        masterServer?.close();
        // await unsubscripToNSD();
        discovery?.dispose();
      }
    });
    if (keepLiveByPingDuration != null) {
      Timer.periodic(keepLiveByPingDuration!, (timer) async {
        String? ip = masterServerSubscriberInfo?.ip;
        try {
          Dio dio = Dio();
          print("START-PING TO $ip:$port  ON ${DateTime.now()}");

          var data = await dio.get("http://$ip:$port/ping");
          if (data.statusCode != 200) {
            throw data.statusMessage ?? '';
          }
          print("Done-PING TO $ip:$port ON ${DateTime.now()}");
        } catch (e) {
          print("Error-PING TO $ip:$port ON ${DateTime.now()}");
          await restart();
        }
      });
    }
  }

  restart() async {
    // isStartMaster = false;

    // await createIpAndPort();
    // await listenToNSD();
    // await unsubscripToNSD();
    // await createMasterServer(ref: true);
    // await subscripToNSD();

    try {
      await server?.close(force: true);
      await unsubscripToNSD();
      await makeMeServerOnShelf();
    } catch (e) {
      print(e.toString());
    }
  }

  restartIfIsEmpty() async {
    // isStartMaster = false;

    // await createIpAndPort();
    // await listenToNSD();
    // await unsubscripToNSD();
    // await createMasterServer(ref: true);
    // await subscripToNSD();

    try {
      bool? isEmpty = await server?.isEmpty;
      if (isEmpty != true) return;
      await server?.close(force: true);
      await unsubscripToNSD();
      await makeMeServerOnShelf();
    } catch (e) {
      print(e.toString());
    }
  }

  createIpAndPort() async {
    String? wifiIP;

    do {
      wifiIP = await infoNetwork.getWifiIP();
    } while (wifiIP == null);

    // final random = Random();
    // final port = random.nextInt(
    //   65536,
    // );
    int port = randomPort();
    masterServerSubscriberInfo = SocketSubscriberInfo(
      imei: deviceId,
      // port: 1996,
      port: port,
      ip: wifiIP,
    );
  }

  createMasterServer({bool ref = false}) async {
    if (networkService.isHasConnectionToNetwork.value == false) return;
    if (isStartMaster && ref == false) return;
    await masterServer?.close();
    // try {
    //   var serverSocket = await ServerSocket.bind(
    //     masterServerSubscriberInfo?.ip,
    //     masterServerSubscriberInfo?.port ?? 1996,
    //     shared: true,
    //   );
    //   await serverSocket.close();
    // } catch (e) {
    //   print("e :${e.toString()}");
    // }

    if (masterServerSubscriberInfo == null || isStartMaster == true) return;

    isStartMaster = true;
    try {
      masterServer = await ServerSocket.bind(
        masterServerSubscriberInfo!.ip,
        masterServerSubscriberInfo!.port!,
        shared: true,
      );
    } catch (e) {
      print(e.toString());
    }
    print(
        "----- START MASTER SERVER ON  ${masterServerSubscriberInfo!.ip}:${masterServerSubscriberInfo!.port!} ----- ");

    masterServer?.listen((client) {
      print("----- START LISTEN TO MASTER SERVER ----- ");
      SocketEventMangment.lisenToServerEvents(client, setResponse: setResponse);
    });

    print("Done");
  }

  String? masterServerIpAndPort(String devId) {
    Service? service = discovery?.services.firstWhereOrNull(
        (element) => convertSeviceToSubscriberInfo(element)?.imei == devId);
    if (service == null) return null;
    var sub = convertSeviceToSubscriberInfo(service);
    return "${sub!.ip}:${sub.port}";
  }

  listenToNSD() async {
    discovery = await startDiscovery(
      '_http._tcp',
    );

    discovery?.addServiceListener((service, status) async {
      bool? isMaster = await checkServiceIsMaster(service);
      if (status == ServiceStatus.found) {
        print('===== Service Found ======');
        print(service.name);

        SocketSubscriberInfo? sub = convertSeviceToSubscriberInfo(service);
        if (sub != null) {
          subscriptions[sub.imei ?? ''] = sub;
        }

        // if (isMaster == true) {
        //   await createMasterServer(ref: true);
        //   await subscripToNSD();
        // }
      } else if (status == ServiceStatus.lost) {
        print('===== Service LOST ======');
        print(service.name);
        // if (isMaster == true && registration != null) {
        //   masterServer?.close();
        //   await unsubscripToNSD();
        // }
      }
      discoverIps();
    });
  }

  subscripToNSD() async {
    if (registration?.id != null) return;
    discovery ??= await startDiscovery(
      '_http._tcp',
    );
    // if (deviceId == null) return;

    Service? service = discovery?.services.firstWhereOrNull(
        (element) => element.name?.split(':')[0] == "d553a948aa7962cf");
    if (service == null) {
      var data = json.encode(masterServerSubscriberInfo?.toJson());
      registration = await register(Service(
        name: data,
        type: '_http._tcp',
        txt: {
          'data': Uint8List.fromList(data.codeUnits),
        },
        host: masterServerSubscriberInfo?.ip,
        port: masterServerSubscriberInfo?.port,
      ));
    }
    print("object");
  }

  unsubscripToNSD() async {
    try {
      if (registration != null) {
        await unregister(registration!);
        registration = null;
      }
    } catch (e) {
      registration = null;
    }
  }

  Service? getServiceByDevice(Device device) =>
      discovery?.services.firstWhereOrNull((element) =>
          convertSeviceToSubscriberInfo(element)?.imei == device.imei);

  SocketSubscriberInfo? convertSeviceToSubscriberInfo(Service? service) {
    if (service == null) return null;
    if (service.txt?['data'] != null) {
      Uint8List uint8List = Uint8List.fromList(service.txt?['data'] ?? []);
      String data = utf8.decode(uint8List);
      return SocketSubscriberInfo.fromJson(json.decode(data));
    }
    return null;
  }

  discoverIps() async {
    // try {
    //   connectedIps.clear();
    //   if (networkService.isHasConnectionToNetwork.value == false) return;
    //   final String? ip = await infoNetwork.getWifiIP();
    //   if (ip == null) return;
    //   final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    //   int port = 1997;

    //   final stream = NetworkAnalyzer.discover2(
    //     subnet,
    //     port,
    //   );

    //   stream.listen((NetworkAddress addr) {
    //     if (addr.exists) {
    //       print('Found device: ${addr.ip}');
    //       connectedIps.add(addr.ip);
    //     }
    //   }).onDone(
    //     () {
    //       lastSuberibersDate.value = DateTime.now();
    //     },
    //   );
    // } catch (e) {
    //   lastSuberibersDate.value = DateTime.now();
    // }
  }

  Future<bool?> checkServiceIsMaster(Service service) async =>
      convertSeviceToSubscriberInfo(service)?.imei == deviceId;

  sendToBordcast(BaseSocketRequest request) {
    List<String> ips = connectedIps.where((element) => true).toList();
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 1997)
        .then((RawDatagramSocket socket) async {
      socket.broadcastEnabled = true;

      for (var element in ips) {
        var socket = await Socket.connect(element, 1997);
        socket.write("*/s${json.encode(request.toJson())}*/d");
      }
    });
  }

  int randomPort() => port ?? 12345;

  List<SocketSubscriberInfo?> getIpAndProdByDeviceId(
      {required List<String> ids}) {
    dev.log('----- subscriptions NSD -----');
    subscriptions.forEach((key, value) {
      dev.log(value.imei ?? '');
    });
    List<SocketSubscriberInfo> subs = subscriptions.values
        .where((element) => ids.contains(element.imei))
        .toList();
    return subs;
  }
}
