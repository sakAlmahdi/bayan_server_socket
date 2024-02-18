import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class BaseNetworkHelper extends GetxService {
  final isHasConnectionToNetwork = false.obs;
  late StreamSubscription<ConnectivityResult> subscription;
  @override
  void onInit() async {
    super.onInit();
    await initConnection();
    checkConnection();
  }

  initConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    checkConnectivityResult(connectivityResult);
  }

  checkConnection() async => subscription = Connectivity()
      .onConnectivityChanged
      .listen((ConnectivityResult result) => checkConnectivityResult(result));

  checkConnectivityResult(ConnectivityResult result) {
    if ([
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
      ConnectivityResult.vpn
    ].contains(result)) {
      isHasConnectionToNetwork.value = true;
    } else {
      isHasConnectionToNetwork.value = false;
    }
  }

  @override
  void onClose() {
    subscription.cancel();
    super.onClose();
  }
}
