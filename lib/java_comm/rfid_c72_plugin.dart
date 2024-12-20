import 'dart:async';
import 'dart:developer';

import 'package:bloc_test_app/business_logic/blocs/box_check/box_check_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:bloc_test_app/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../business_logic/cubit/navigaion_qubit_cubit.dart';
import '../data/models/variables.dart';

class RfidC72Plugin {
  static const MethodChannel _channel = MethodChannel('rfid_c72_plugin');
  static const MethodChannel _keyEventChannel =
      MethodChannel('com.example.my_rfid_plugin/key_events');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static const EventChannel connectedStatusStream =
      EventChannel('ConnectedStatus');
  static const EventChannel tagsStatusStream = EventChannel('TagsStatus');

  static Future<bool?> get isStarted async {
    return _channel.invokeMethod('isStarted');
  }

  static Future<bool?> get startSingle async {
    return _channel.invokeMethod('startSingle');
  }

  static Future<bool?> get startContinuous async {
    return _channel.invokeMethod('startContinuous');
  }

  static Future<bool?> get startContinuous2 async {
    return _channel.invokeMethod('startContinuous2');
  }

  static Future<bool?> get stop async {
    return _channel.invokeMethod('stop');
  }

  static Future<bool?> get close async {
    return _channel.invokeMethod('close');
  }

  static Future<bool?> get clearData async {
    return _channel.invokeMethod('clearData');
  }

  static Future<bool?> get isEmptyTags async {
    return _channel.invokeMethod('isEmptyTags');
  }

  static Future<bool?> get connect async {
    return _channel.invokeMethod('connect');
  }

  static Future<bool?> get isConnected async {
    return _channel.invokeMethod('isConnected');
  }

  static Future<bool?> get connectBarcode async {
    return _channel.invokeMethod('connectBarcode');
  }

  static Future<bool?> get scanBarcode async {
    return _channel.invokeMethod('scanBarcode');
  }

  static Future<bool?> get stopScan async {
    return _channel.invokeMethod('stopScan');
  }

  static Future<bool?> get closeScan async {
    return _channel.invokeMethod('closeScan');
  }

  static Future<bool?> setPowerLevel(String value) async {
    return _channel
        .invokeMethod('setPowerLevel', <String, String>{'value': value});
  }

  static Future<bool?> setWorkArea(String value) async {
    return _channel
        .invokeMethod('setWorkArea', <String, String>{'value': value});
  }

  static Future<String?> get readBarcode async {
    final String? barcode = await _channel.invokeMethod('readBarcode');
    return barcode;
  }

  static Future<bool?> get playSound async {
    return _channel.invokeMethod('playSound');
  }

  static Future<String?> get getPowerLevel async {
    final String? powerLevel = await _channel.invokeMethod('getPowerLevel');
    return powerLevel;
  }

  static Future<String?> get getFrequencyMode async {
    final String? frequencyMode =
        await _channel.invokeMethod('getFrequencyMode');
    return frequencyMode;
  }

  static Future<String?> get getTemperature async {
    final String? getTemperature =
        await _channel.invokeMethod('getTemperature');
    return getTemperature;
  }

  static Future<bool?> writeTag(String value) async {
    final result = await _channel
        .invokeMethod('writeTag', <String, String>{'value': value});
    return result;
  }

  static Future<bool?> writeTag2(String value) async {
    final result = await _channel
        .invokeMethod('writeTag2', <String, String>{'value': value});
    return result;
  }

  // Key Event Handling
  static void initializeKeyEventHandler(BuildContext context) {
    _keyEventChannel
        .setMethodCallHandler((call) => _handleKeyEvent(call, context));
  }

  static Future<void> _handleKeyEvent(
      MethodCall call, BuildContext context) async {
    log('Handle key event OK');

    final dbState = context.read<DBTagBloc>().state;
    final pageIndex = context.read<NavigationCubit>().state;
    log(pageIndex.toString());
    log(globalDataToWriteTag);
    switch (call.method) {
      case 'onKeyDown':
        int keyCode = call.arguments;
        log('Key down: $keyCode');
        if (dbState is DBTagLoaded) {
          if (pageIndex == 1) {
            context.read<BoxCheckBloc>().add(BoxCheckStart(dbState.tags));
            Timer(const Duration(seconds: 5), () {
              context.read<BoxCheckBloc>().add(BoxCheckStop());
            });
          } else if (pageIndex == 2) {
            context.read<RfidTagBloc>().add(RfidScanStart(dbState.tags));
            Timer(const Duration(seconds: 5), () {
              context.read<RfidTagBloc>().add(RfidScanStop());
            });
          } else if (pageIndex == 4) {
            await writeTag2(globalDataToWriteTag);
          }
        }
        break;
      case 'onKeyUp':
        int keyCode = call.arguments;
        log('Key up: $keyCode');

        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }
}
