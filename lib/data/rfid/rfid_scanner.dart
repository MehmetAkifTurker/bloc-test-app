import 'package:bloc_test_app/data/models/tag_epc.dart';
import 'package:bloc_test_app/java_comm/rfid_c72_plugin.dart';
import 'package:flutter/services.dart';

class RfidScanner {
  String _platformVersion = 'Unknown';
  final bool _isHaveSavedData = false;
  final bool _isStarted = false;
  final bool _isEmptyTags = false;
  bool _isConnected = false;
  bool _isLoading = true;
  int _totalEPC = 0, _invalidEPC = 0, _scannedEPC = 0;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = (await RfidC72Plugin.platformVersion)!;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    RfidC72Plugin.connectedStatusStream
        .receiveBroadcastStream()
        .listen(updateIsConnected);
    RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(updateTags);
    await RfidC72Plugin.connect;
// await UhfC72Plugin.setWorkArea('2');
// await UhfC72Plugin.setPowerLevel('30');
// If the widget was removed from the tree while the asynchronous platform
// message was in flight, we want to discard the reply rather than calling
// setState to update our non-existent appearance.

    await RfidC72Plugin.connectBarcode; //connect barcode

    _platformVersion = platformVersion;
    _isLoading = false;
  }

  List<TagEpc> _data = [];
  final List<String> _EPC = [];

  void updateTags(dynamic result) async {
    _data = TagEpc.parseTags(result);
    _totalEPC = _data.toSet().toList().length;
  }

  void updateIsConnected(dynamic isConnected) {
    _isConnected = isConnected;
  }

  final bool _isContinuousCall = false;
  final bool _is2dscanCall = false;

  String get platformVersion => _platformVersion;
}
