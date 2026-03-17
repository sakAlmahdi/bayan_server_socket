import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class BaseNetworkHelper extends GetxService {
  final isHasConnectionToNetwork = false.obs;
  late StreamSubscription<List<ConnectivityResult>> subscription;
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

  checkConnection() async =>
      subscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> result) => checkConnectivityResult(result));

  checkConnectivityResult(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.vpn)) {
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
