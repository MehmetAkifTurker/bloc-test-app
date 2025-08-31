import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';
import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:flutter/services.dart';

class RfidScanner {
  String _platformVersion = 'Unknown';
  final bool _isHaveSavedData = false;
  final bool _isStarted = false;
  final bool _isEmptyTags = false;
  bool _isConnected = false;
  bool _isLoading = true;
  int _totalEPC = 0, _invalidEPC = 0, _scannedEPC = 0;

  // RfidC72Plugin streams
  // - connectedStatusStream -> calls updateIsConnected
  // - tagsStatusStream -> calls updateTags

  List<TagEpc> _data = [];
  final List<String> _EPC = [];

  final bool _isContinuousCall = false;
  final bool _is2dscanCall = false;

  String get platformVersion => _platformVersion;

  /// Asynchronously initialize the plugin data.
  /// We do NOT call RfidC72Plugin.connect here anymore.
  Future<void> initPlatformState() async {
    String platformVersion;

    try {
      platformVersion = (await RfidC72Plugin.platformVersion) ?? 'Unknown';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // Subscribe to connected and tag streams
    RfidC72Plugin.connectedStatusStream
        .receiveBroadcastStream()
        .listen(updateIsConnected);

    RfidC72Plugin.tagsStatusStream.receiveBroadcastStream().listen(updateTags);

    // If you want to connect to 2D barcode scanning here:
    await RfidC72Plugin.connectBarcode; // If you need the 2D scanner
    // (Remove it if you want to connect the scanner once at a higher level, too.)

    _platformVersion = platformVersion;
    _isLoading = false;
  }

  /// Called whenever the tagsStatusStream emits a new set of tags.
  void updateTags(dynamic result) {
    _data = TagEpc.parseTags(result);
    _totalEPC = _data.toSet().length;
  }

  /// Called whenever the connectedStatusStream emits a bool for isConnected.
  void updateIsConnected(dynamic isConnectedValue) {
    _isConnected = (isConnectedValue == true);
  }
}
