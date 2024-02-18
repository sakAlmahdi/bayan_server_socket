class BaseSocketEvent {
  //control
  static const String ping = 'ping';

  //Shift Mangement
  static const String hasShitf = 'HasShift';
  static const String openShitf = 'OpenShift';
  static const String closeShitf = 'CloseShift';
  static const String getShifts = 'getShifts';
  static const String clockOutShifts = 'clockOutShifts';
  //till Mangement
  static const String hasTill = 'hasTill';
  static const String openTill = 'OpenTill';
  static const String closeTill = 'CloseTill';
  static const String getAllTillOpened = 'getAllTillOpened';
  static const String getTillsByDate = 'getTillsByDate';

  static const String tillUserHistory = 'tillUserHistory';
  static const String tillStream = "tillStream";

  //Login history
  static const String loginWriteLog = 'loginWriteLog';
  static const String logoutWriteLog = 'logoutWriteLog';
  static const String hasLoginLog = 'hasLoginLog';

  static const String syncOrder = 'syncOrder';
  static const String syncBulkOrders = 'syncBulkOrders';
  static const String getOrders = 'GetOrders';
  static const String changeOrder = 'changeOrder';
  static const String newSyncBlukOrders = 'newSyncBlukOrders';
  static const String lockOrder = 'lockOrder';
  static const String createOrderNumber = 'createOrderNumber';

  static const String getOrderCallNumber = 'getOrderCallNumber';

  static const String closeDayReportSumary = 'closeDayReportSumary';

  //Kitchen
  static const String sendOrderToKDS = 'SendOrderToKDS';
  static const String receivingOrderFromMainCashier =
      'receivingOrderFromMainCashier';
}
