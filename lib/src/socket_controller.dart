// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';

// import 'package:bayan_pos_core/core/extensions/base_map_extension.dart';
// import 'package:bayan_pos_core/data/modle/device/device.dart';
// import 'package:bayan_pos_core/data/modle/socket/socket.dart';
// import 'package:bayan_pos_core/data/modle/socket/socket_request.dart';
// import 'package:bayan_pos_core/data/modle/socket/socket_subscriber%D9%80Info.dart';

// import 'package:bayan_socket_server/core/halpers/base_network_helper.dart';
// import 'package:bayan_socket_server/core/keys/keys.dart';

// import 'package:bayan_socket_server/src/socket_event_mangment.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:get/get_state_manager/get_state_manager.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:nsd/nsd.dart';

// class SocketController extends GetxController {
//   SocketController({
//     required this.allDevices,
//     required this.deviceId,
//     this.userId,
//     required this.setResponse,
//   });
//   final networkService = Get.put(BaseNetworkHelper(), permanent: true);
//   ServerSocket? meServerSocket;
//   SocketSubscriberInfo? masterSubscriberInfo;
//   Discovery? discovery;
//   // ActivationController activationController = Get.find<ActivationController>();
//   final isMasterOnline = false.obs;
//   Registration? registration;
//   NetworkInfo infoNetwork = NetworkInfo();

//   final networkName = "".obs;
//   Device? masterDev;
//   SocketSubscriberInfo? meSubscriberInfo;

//   late List<Device> allDevices;
//   late String deviceId;

//   String? userId;
//   bool isStartMeServer = false;
//   BaseSocketResponse? Function(BaseSocketRequest request) setResponse;

//   @override
//   Future<void> onInit() async {
//     super.onInit();

//     // receivePort?.listen((message) { });
//   }

//   initServers() async {
//     // return;

//     // var serverSocket = await ServerSocket.bind('localhost', 1997);
//     // await serverSocket.close();

//     if (deviceId == 'd553a948aa7962cf') {
//       deviceId = "d553a948aa7962cf--overide";
//     }
//     networkName.value = await infoNetwork.getWifiName() ?? '';
//     await crearMeIpAndPort();
//     await listenToNSD();
//     await subscripToNSD();
//     await createMeServer();
//     ever(networkService.isHasConnectionToNetwork, (callback) async {
//       if (callback == true) {
//         await unsubscripToNSD();
//         await subscripToNSD();
//         await createMeServer(ref: true);
//       } else {
//         await unsubscripToNSD();
//         // await meServerSocket?.close();

//         // await meServerSocket?.close();
//       }
//     });

//     // Timer.periodic(Duration(seconds: 30), (timer) {
//     //   createMeServer(ref: true);
//     // });
//   }

//   crearMeIpAndPort() async {
//     final wifiIP = await infoNetwork.getWifiIP();
//     meSubscriberInfo = SocketSubscriberInfo(
//       imei: deviceId,
//       port: 1997,
//       ip: wifiIP,
//       deviceId: deviceId,
//       userId: userId,
//     );
//   }

//   createMeServer({bool ref = false}) async {
//     // if (networkService.isHasConnectionToNetwork.value == false) return;

//     // String? connection = masterServerIpAndPort(deviceId);
//     if (meSubscriberInfo == null) return;
//     // await meServerSocket?.close();
//     if (meServerSocket != null) {
//       meServerSocket?.close();
//     }

//     // isStartMaster = true;
//     meServerSocket = await ServerSocket.bind(
//       meSubscriberInfo!.ip,
//       meSubscriberInfo!.port!,
//       shared: true,
//     ).then((value) {
//       print(
//           "----- START Me SERVER ON   ${meSubscriberInfo!.ip}:${meSubscriberInfo!.port!} ----- ");
//       value.listen((event) {
//         print("----- START LISTEN TO Me SERVER ----- ");
//         SocketEventMangment.lisenToServerEvents(event,
//             setResponse: setResponse);
//       });
//     });

//     print("Done");

//     print("CHECK SERVER CONNECTION ");

//     // bool isConnect = await checkIpAndProt();
//     bool isConnect = true;

//     print("STATUS $isClosed");

//     if (!isConnect) {
//       changePort();
//       print("CHANGE PORT ${meSubscriberInfo?.port}");
//       await unsubscripToNSD();
//       await subscripToNSD();
//       await createMeServer(ref: true);
//     }
//   }

//   changePort() async {
//     meSubscriberInfo?.port = Random().nextInt(1990);
//   }

//   listenToNSD() async {
//     discovery = await startDiscovery(
//       '_http._tcp',
//     );

//     discovery?.addServiceListener((service, status) async {
//       // bool? isMaster = await checkServiceIsMaster(service);
//       if (status == ServiceStatus.found) {
//         print('===== Service Found ======');
//         print("${service.name}");
//         // if (isMaster == true) {
//         //   masterSubscriberInfo = convertSeviceToSubscriberInfo(service);
//         //   isMasterOnline.value = true;
//         // }
//       } else if (status == ServiceStatus.lost) {
//         print('===== Service LOST ======');
//         print("${service.name}");

//         // if (isMaster == true) {
//         //   isMasterOnline.value = false;
//         // }
//       }
//       checkMasterIsOnline(imei: convertSeviceToSubscriberInfo(service)?.imei);
//     });
//   }

//   checkMasterIsOnline({String? imei}) async {
//     Device? device = allDevices.firstWhereOrNull(
//         (element) => element.deviceTypeCode == DeviceTypeCode.cashier);
//     List<Service> services = discovery?.services
//             .where((element) =>
//                 convertSeviceToSubscriberInfo(element)?.imei == device?.imei)
//             .toList() ??
//         [];
//     Service? service = services.isNotEmpty ? services.last : null;

//     if (service != null) {
//       masterSubscriberInfo = convertSeviceToSubscriberInfo(service);
//       isMasterOnline.value = true;
//     } else {
//       isMasterOnline.value = false;
//     }
//   }

//   subscripToNSD() async {
//     if (registration?.id != null) return;
//     // if (deviceId == null) return;

//     List<Service> services = discovery?.services
//             .where(
//                 (element) => element.name?.split(':')[0] == "d553a948aa7962cf")
//             .toList() ??
//         [];

//     Service? service = services.isNotEmpty ? services.last : null;
//     if (service == null) {
//       var data = json.encode(meSubscriberInfo?.toJson());
//       registration = await register(Service(
//         name: meSubscriberInfo?.toJson().toString(),
//         type: '_http._tcp',
//         host: meSubscriberInfo?.ip,
//         txt: {
//           'data': Uint8List.fromList(data.codeUnits),
//         },
//         port: 1997,
//       ));
//     }
//   }

//   unsubscripToNSD() async {
//     try {
//       if (registration != null) {
//         await unregister(registration!);
//         registration = null;
//       }
//     } catch (e) {
//       registration = null;
//     }
//   }

//   String converReqToString(BaseSocketRequest req) {
//     var request = req
//         .copyWith(
//           fromIp: meSubscriberInfo?.ip,
//           port: meSubscriberInfo?.port,
//         )
//         .toJson()
//         .removeNull();
//     var jsonD = json.encode(request);

//     return "*/s$jsonD*/d";
//   }

//   SocketSubscriberInfo? convertSeviceToSubscriberInfo(Service service) {
//     if (service.txt?['data'] != null) {
//       Uint8List uint8List = Uint8List.fromList(service.txt?['data'] ?? []);
//       String data = utf8.decode(uint8List);
//       return SocketSubscriberInfo.fromJson(json.decode(data));
//     }
//     return null;
//   }

//   Future<bool?> checkServiceIsMaster(Service service) async {
//     Device? device = allDevices.firstWhereOrNull(
//         (element) => element.deviceTypeCode == DeviceTypeCode.cashier);
//     return convertSeviceToSubscriberInfo(service)?.imei == device?.imei;
//   }

//   List<SocketSubscriberInfo?> getIpAndProdByDeviceId(
//       {required List<String> ids}) {
//     List<SocketSubscriberInfo?> subs = discovery?.services
//             .map((e) => convertSeviceToSubscriberInfo(e))
//             .toList() ??
//         [];

//     subs = subs.where((element) => ids.contains(element?.imei)).toList();
//     return subs;
//   }

//   Future<bool> checkIpAndProt() async {
//     try {
//       final completer = Completer<bool>();
//       completer.future.timeout(const Duration(seconds: 15),
//           onTimeout: () async {
//         completer.complete(false);
//         return false;
//       });
//       await Socket.connect(
//         meSubscriberInfo!.ip,
//         meSubscriberInfo!.port!,
//       ).then((value) {
//         value.write("test");
//         value.listen((event) {
//           completer.complete(true);
//         });
//       }).catchError((e) {
//         completer.complete(false);
//       });
//       return completer.future;
//     } catch (e) {
//       return false;
//     }
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bayan_pos_core/data/model/device/device.dart';
import 'package:bayan_pos_core/data/model/socket/socket.dart';
import 'package:bayan_pos_core/data/model/socket/socket_request.dart';
import 'package:bayan_socket_server/core/halpers/base_network_helper.dart';
import 'package:bayan_socket_server/src/socket_event_mangment.dart';
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

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  startShelfServer(Handler handler) {
    this.handler = handler;
    makeMeServerOnShelf();
    ever(networkService.isHasConnectionToNetwork, (callback) async {
      if (callback == true) {
        await makeMeServerOnShelf();
      } else {
        await server?.close();
        await unsubscripToNSD();
        // await unsubscripToNSD();
      }
    });
  }

  makeMeServerOnShelf() async {
    print("createIpAndPort");
    await createIpAndPort();
    print("listenToNSD");
    try {
      await listenToNSD();
    } catch (e) {
      print(e.toString());
    }
    print("subscripToNSD");
    try {
      await subscripToNSD();
    } catch (e) {}
    print("server");
    // if (server.)
    try {
      // await server?.close();
      // var handler =
      //     const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

      server = await shelf_io.serve(
        handler!.call,
        masterServerSubscriberInfo!.ip!,
        masterServerSubscriberInfo!.port!,
        // 0,
        shared: true,
      );

      masterServerSubscriberInfo?.port = server?.port;

      if (server != null) return;

      // Enable content compression
      server?.autoCompress = true;

      server?.idleTimeout = const Duration(days: 1);
      server?.sessionTimeout = 86400 * 30;

      print('Serving at http://${server?.address.host}:${server?.port}');
    } catch (e) {
      print("BAYAN ERROR : ${e.toString()}");
    }
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

  createIpAndPort() async {
    final wifiIP = await infoNetwork.getWifiIP();
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
    List<SocketSubscriberInfo> subs = subscriptions.values
        .where((element) => ids.contains(element.imei))
        .toList();
    return subs;
  }
}
