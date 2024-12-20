import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/data/models/optimized_tag_rfid_scan.dart';

import 'package:bloc_test_app/data/models/rfid_status.dart';
import 'package:bloc_test_app/data/models/tag_epc.dart';
import 'package:bloc_test_app/java_comm/rfid_c72_plugin.dart';
import 'package:equatable/equatable.dart';

part 'rfid_tag_event.dart';
part 'rfid_tag_state.dart';

class RfidTagBloc extends Bloc<RfidTagEvent, RfidTagState> {
  // late StreamSubscription _subscription;
  int previousTagsCount = 0;
  RfidStatus statusVariable = RfidStatus(
      connectingStatus: false,
      platformName: '',
      getPower: '',
      getTemperature: '',
      getFrequencyMode: '');

  RfidTagBloc() : super(RfidIdle()) {
    on<RfidInit>(
      (event, emit) async {
        bool? result = false;
        previousTagsCount = 0;

        final isconnected = await RfidC72Plugin.isConnected;
        log('rfid_tag_bloc - isConnected = ${isconnected.toString()}');
        if (isconnected == false) {
          result = await RfidC72Plugin.connect;
          log('rfid_tag_bloc - connecting result = ${result.toString()}');
        }

        if (isconnected == true || result == true) {
          try {
            final isReading = await RfidC72Plugin.isStarted;
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
        statusVariable.connectingStatus = isconnected ?? false;
        final platformName = (isconnected == true || result == true)
            ? await RfidC72Plugin.platformVersion
            : 'Could not get the platform name';
        log('rfid_tag_bloc - platform Name = $platformName');
        statusVariable.platformName = platformName!;

        try {
          final getPowerLevel = (isconnected == true || result == true)
              ? await RfidC72Plugin.getPowerLevel
              : 'Could not get power';
          log('rfid_tag_bloc - get Power Level = $getPowerLevel');

          statusVariable.getPower = getPowerLevel ?? '';
        } catch (e) {
          log('rfid_tag_bloc - Get Power Error ${e.toString()}');
        }
        try {
          final getTemperature = (isconnected == true || result == true)
              ? await RfidC72Plugin.getTemperature
              : 'Could not get temperature';

          statusVariable.getTemperature = getTemperature ?? '';

          log('rfid_tag_bloc - get Temperature = $getTemperature');
        } catch (e) {
          log('rfid_tag_bloc - Get Temperature ${e.toString()}');
        }

        try {
          final getFrequencyMode = (isconnected == true || result == true)
              ? await RfidC72Plugin.getFrequencyMode
              : 'Could not get frequency mode';

          statusVariable.getFrequencyMode = getFrequencyMode ?? '';

          log('rfid_tag_bloc - get Frequency Mode = $getFrequencyMode');
        } catch (e) {
          log('rfid_tag_bloc - Get Power Error ${e.toString()}');
        }
        // if (isconnected == true || result == true) {
        //   emit(TagInitialisOK(status));
        // }

        try {
          final clearResult = await RfidC72Plugin.clearData;
          log('Clear result is = $clearResult');
        } catch (e) {
          log('Can not clear data = $e');
        }
        log('Status is $statusVariable');
        emit(RfidInitializing(status: statusVariable));
      },
    );

    on<RfidSetPower>(
      (event, emit) async {
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
        emit((RfidInitializing(status: statusVariable)));
      },
    );
    on<RfidScanStart>((event, emit) async {
      final isScanning = await RfidC72Plugin.isStarted;
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
                  notFoundInDBTags: notFoundInDBTags);

              if (previousTagsCount != newTags.length) {
                RfidC72Plugin.playSound;
                previousTagsCount = newTags.length;
              }

              return RfidScanning(
                //tags: [...state.tags, ...newTags],
                tags: newTags,
                optimizedTag: optimizedTag,
                foundInDBTags: foundInDBTags,
                notFoundInDBTags: notFoundInDBTags,
              );
            },
            onError: (error, stackTrace) {
              // Handle error
              log('Error: $error');
              return RfidError(); // Or any appropriate error state
            },
          );
        } catch (e) {
          // Handle startContinuous error
          log('Error starting continuous scan: $e');
          // Emit error state if needed
        }
      }
    });

    on<RfidScanStop>((event, emit) async {
      await RfidC72Plugin.stop;
      if (state is RfidScanning) {
        emit(RfidScanning(
          tags: (state as RfidScanning).tags,
          optimizedTag: (state as RfidScanning).optimizedTag,
          foundInDBTags: (state as RfidScanning).foundInDBTags,
          notFoundInDBTags: (state as RfidScanning).notFoundInDBTags,
        ));
      }
    });

    on<RfidFilterTags>((event, emit) {
      if (state is RfidScanning) {
        emit(RfidScanning(
          tags: (state as RfidScanning).tags,
          selectedFilter: event.filter,
          optimizedTag: (state as RfidScanning).optimizedTag,
          foundInDBTags: (state as RfidScanning).foundInDBTags,
          notFoundInDBTags: (state as RfidScanning).notFoundInDBTags,
        ));
      }
    });

    // on<TagScanInit>((event, emit) async {});

    // on<TagScanInit>((event, emit) async {});
  }
}
