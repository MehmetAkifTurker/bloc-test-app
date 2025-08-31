import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:water_boiler_rfid_labeler/data/models/optimized_tag_rfid_scan.dart';
import 'package:water_boiler_rfid_labeler/data/models/rfid_status.dart';
import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';
import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:equatable/equatable.dart';

part 'rfid_tag_event.dart';
part 'rfid_tag_state.dart';

class RfidTagBloc extends Bloc<RfidTagEvent, RfidTagState> {
  int previousTagsCount = 0;
  RfidStatus statusVariable = RfidStatus(
    connectingStatus: false,
    platformName: '',
    getPower: '',
    getTemperature: '',
    getFrequencyMode: '',
  );

  RfidTagBloc() : super(RfidIdle()) {
    // 1) RfidInit no longer calls connect - it just checks isConnected
    on<RfidInit>((event, emit) async {
      previousTagsCount = 0;

      // Check if the device is already connected
      final bool? isConnected = await RfidC72Plugin.isConnected;
      log('rfid_tag_bloc - isConnected = $isConnected');

      // We do NOT call RfidC72Plugin.connect here anymore
      final bool actuallyConnected = (isConnected == true);

      // If connected, we can stop scanning and clear data if needed
      if (actuallyConnected) {
        try {
          final bool? isReading = await RfidC72Plugin.isStarted;
          if (isReading == true) {
            try {
              await RfidC72Plugin.stop;
            } catch (e) {
              log('rfid_tag_bloc - Cannot Stop  ${e.toString()}');
            }
          }
          await RfidC72Plugin.clearData;
        } catch (e) {
          log('rfid_tag_bloc - Cannot Clear Data  ${e.toString()}');
        }
      }

      // Update the status
      statusVariable.connectingStatus = actuallyConnected;
      // If connected, we can get the platform version
      final platformName = actuallyConnected
          ? await RfidC72Plugin.platformVersion
          : 'Could not get the platform name';
      log('rfid_tag_bloc - platform Name = $platformName');
      statusVariable.platformName = platformName!;

      // Get power level if connected, else store placeholder
      try {
        final getPowerLevel = actuallyConnected
            ? await RfidC72Plugin.getPowerLevel
            : 'Could not get power';
        log('rfid_tag_bloc - get Power Level = $getPowerLevel');
        statusVariable.getPower = getPowerLevel ?? '';
      } catch (e) {
        log('rfid_tag_bloc - Get Power Error ${e.toString()}');
      }

      // getTemperature
      try {
        final getTemperature = actuallyConnected
            ? await RfidC72Plugin.getTemperature
            : 'Could not get temperature';
        statusVariable.getTemperature = getTemperature ?? '';
        log('rfid_tag_bloc - get Temperature = $getTemperature');
      } catch (e) {
        log('rfid_tag_bloc - Get Temperature ${e.toString()}');
      }

      // getFrequencyMode
      try {
        final getFrequencyMode = actuallyConnected
            ? await RfidC72Plugin.getFrequencyMode
            : 'Could not get frequency mode';
        statusVariable.getFrequencyMode = getFrequencyMode ?? '';
        log('rfid_tag_bloc - get Frequency Mode = $getFrequencyMode');
      } catch (e) {
        log('rfid_tag_bloc - Get Frequency Mode Error ${e.toString()}');
      }

      try {
        final clearResult = await RfidC72Plugin.clearData;
        log('Clear result is = $clearResult');
      } catch (e) {
        log('Can not clear data = $e');
      }

      log('Status is $statusVariable');
      emit(RfidInitializing(status: statusVariable));
    });

    // 2) RfidSetPower - same as before
    on<RfidSetPower>((event, emit) async {
      try {
        final setPowerResult =
            await RfidC72Plugin.setPowerLevel(event.powerLevel);
        log('Set Power Level Result is = $setPowerResult');
      } catch (e) {
        log('rfid_tag_bloc - Can not set Power = $e');
      }

      final getPowerLevel = await RfidC72Plugin.getPowerLevel;
      statusVariable.getPower = getPowerLevel ?? statusVariable.getPower;
      emit(RfidIdle());
      emit(RfidInitializing(status: statusVariable));
    });

    // 3) RfidScanStart - same as before, no connect calls
    on<RfidScanStart>((event, emit) async {
      final bool? isScanning = await RfidC72Plugin.isStarted;
      Set<DBTag> foundInDBTags = {};
      Set<TagEpc> notFoundInDBTags = {};

      if (isScanning == false) {
        try {
          await RfidC72Plugin.startContinuous;
          emit(
            const RfidScanning(
              tags: [],
              optimizedTag: [],
              foundInDBTags: {},
              notFoundInDBTags: {},
            ),
          );
          await emit.forEach(
            RfidC72Plugin.tagsStatusStream.receiveBroadcastStream(),
            onData: (result) {
              final newTags = TagEpc.parseTags(result);

              final optimizedTag = processRfidScanTags(
                tags: newTags,
                dbTags: event.dbTags,
                foundInDBTags: foundInDBTags,
                notFoundInDBTags: notFoundInDBTags,
              );

              if (previousTagsCount != newTags.length) {
                RfidC72Plugin.playSound;
                previousTagsCount = newTags.length;
              }

              return RfidScanning(
                tags: newTags,
                optimizedTag: optimizedTag,
                foundInDBTags: foundInDBTags,
                notFoundInDBTags: notFoundInDBTags,
              );
            },
            onError: (error, stackTrace) {
              log('Error: $error');
              return RfidError(); // Or any appropriate error state
            },
          );
        } catch (e) {
          log('Error starting continuous scan: $e');
          // Emit error state if needed
        }
      }
    });

    // 4) RfidScanStop - unchanged
    on<RfidScanStop>((event, emit) async {
      await RfidC72Plugin.stop;
      if (state is RfidScanning) {
        final s = state as RfidScanning;
        emit(RfidScanning(
          tags: s.tags,
          optimizedTag: s.optimizedTag,
          foundInDBTags: s.foundInDBTags,
          notFoundInDBTags: s.notFoundInDBTags,
        ));
      }
    });

    // 5) RfidFilterTags - unchanged
    on<RfidFilterTags>((event, emit) {
      if (state is RfidScanning) {
        final s = state as RfidScanning;
        emit(RfidScanning(
          tags: s.tags,
          selectedFilter: event.filter,
          optimizedTag: s.optimizedTag,
          foundInDBTags: s.foundInDBTags,
          notFoundInDBTags: s.notFoundInDBTags,
        ));
      }
    });
  }
}
