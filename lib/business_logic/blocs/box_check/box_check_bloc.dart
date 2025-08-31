import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:water_boiler_rfid_labeler/data/models/optimized_tag_box_scan.dart';
import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';
import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:equatable/equatable.dart';
import 'package:water_boiler_rfid_labeler/data/models/rfid_status.dart';

part 'box_check_event.dart';
part 'box_check_state.dart';

class BoxCheckBloc extends Bloc<BoxCheckEvent, BoxCheckState> {
  int previousTagsCount = 0;
  RfidStatus statusVariable = RfidStatus(
    connectingStatus: false,
    platformName: '',
    getPower: '',
    getTemperature: '',
    getFrequencyMode: '',
  );

  BoxCheckBloc() : super(BoxCheckIdle()) {
    // 1) BoxCheckInit no longer re-connects
    on<BoxCheckInit>((event, emit) async {
      previousTagsCount = 0;

      // Just check if connected (we do NOT call .connect)
      final bool? isConnected = await RfidC72Plugin.isConnected;
      log('rfid_boxcheck_bloc - isConnected = $isConnected');

      // If we are connected, we can do extra steps (stop scanning, clear data, etc.)
      final bool actuallyConnected = (isConnected == true);

      // Clear existing data only if already connected
      if (actuallyConnected) {
        try {
          final bool? isReading = await RfidC72Plugin.isStarted;
          if (isReading == true) {
            try {
              await RfidC72Plugin.stop;
            } catch (e) {
              log('rfid_boxcheck_bloc - Cannot Stop  ${e.toString()}');
            }
          }
          await RfidC72Plugin.clearData;
        } catch (e) {
          log('rfid_boxcheck_bloc - Cannot Clear Data  ${e.toString()}');
        }
      }

      // Update status
      statusVariable.connectingStatus = actuallyConnected;
      final platformName = actuallyConnected
          ? await RfidC72Plugin.platformVersion
          : 'Could not get the platform name';
      log('rfid_boxcheck_bloc - platform Name = $platformName');
      statusVariable.platformName = platformName!;

      // For demonstration, set power = '5' always (only if connected)
      if (actuallyConnected) {
        try {
          await RfidC72Plugin.setPowerLevel('5');
        } catch (e) {
          log('rfid_boxcheck_bloc - Set Power Error ${e.toString()}');
        }
      }

      // getPowerLevel
      try {
        final getPowerLevel = actuallyConnected
            ? await RfidC72Plugin.getPowerLevel
            : 'Could not get power';
        log('rfid_boxcheck_bloc - get Power Level = $getPowerLevel');
        statusVariable.getPower = getPowerLevel ?? '';
      } catch (e) {
        log('rfid_boxcheck_bloc - Get Power Error ${e.toString()}');
      }

      // getTemperature
      try {
        final getTemperature = actuallyConnected
            ? await RfidC72Plugin.getTemperature
            : 'Could not get temperature';
        statusVariable.getTemperature = getTemperature ?? '';
        log('rfid_boxcheck_bloc - get Temperature = $getTemperature');
      } catch (e) {
        log('rfid_boxcheck_bloc - Get Temperature ${e.toString()}');
      }

      // getFrequencyMode
      try {
        final getFrequencyMode = actuallyConnected
            ? await RfidC72Plugin.getFrequencyMode
            : 'Could not get frequency mode';
        statusVariable.getFrequencyMode = getFrequencyMode ?? '';
        log('rfid_boxcheck_bloc - get Frequency Mode = $getFrequencyMode');
      } catch (e) {
        log('rfid_boxcheck_bloc - Get Frequency Error ${e.toString()}');
      }

      try {
        final clearResult = await RfidC72Plugin.clearData;
        log('Clear result is = $clearResult');
      } catch (e) {
        log('Can not clear data = $e');
      }

      log('Status is $statusVariable');
      emit(BoxCheckInitializing(status: statusVariable));
    });

    on<BoxCheckSetPower>((event, emit) async {
      try {
        final setPowerResult =
            await RfidC72Plugin.setPowerLevel(event.powerLevel);
        log('Set Power Level Result is = $setPowerResult');
      } catch (e) {
        log('rfid_boxcheck_bloc - Can not set Power = $e');
      }

      final getPowerLevel = await RfidC72Plugin.getPowerLevel;
      statusVariable.getPower = getPowerLevel ?? statusVariable.getPower;
      emit(BoxCheckIdle());
      emit(BoxCheckInitializing(status: statusVariable));
    });

    on<BoxCheckStart>((event, emit) async {
      final bool? isScanning = await RfidC72Plugin.isStarted;
      String foundMaster = '';
      Set<DBTag> foundSlaveTagsOfFoundMaster = {};
      Set<DBTag> unfoundSlaveTagsOfFoundMaster = {};
      Set<DBTag> foundSlaveTagsOfOtherMasters = {};
      Set<DBTag> allSlaveTagInDBOfFoundMaster = {};
      int allSlaveTagInDBOfFoundMasterLenght = 0;

      await RfidC72Plugin.clearData;
      foundSlaveTagsOfFoundMaster.clear();
      unfoundSlaveTagsOfFoundMaster.clear();
      foundSlaveTagsOfOtherMasters.clear();
      log(isScanning.toString());

      if (isScanning == false) {
        try {
          await RfidC72Plugin.setPowerLevel('5');
          await RfidC72Plugin.startContinuous;
          emit(
            const BoxCheckScanning(
              tags: [],
              foundMaster: '',
              optimizedTags: [],
              foundSlaveTagsOfFoundMaster: {},
              foundSlaveTagsOfOtherMasters: {},
              allSlaveTagInDBOfFoundMaster: {},
              unfoundSlaveTagsOfFoundMaster: {},
            ),
          );

          await emit.forEach(
            RfidC72Plugin.tagsStatusStream.receiveBroadcastStream(),
            onData: (result) {
              final newTags = TagEpc.parseTags(result);

              final optimizedTags = processBoxScanTags(
                tags: newTags,
                dbTags: event.dbTags,
                masterTagName: foundMaster,
                foundSlaveTagsOfFoundMaster: foundSlaveTagsOfFoundMaster,
                foundSlaveTagsOfOtherMaster: foundSlaveTagsOfOtherMasters,
                allSlaveTagInDBOfFoundMaster: allSlaveTagInDBOfFoundMaster,
                unfoundSlaveTagsOfFoundMaster: unfoundSlaveTagsOfFoundMaster,
              );

              log('************1 AllSlaveTagsInDBOfFoundMaster = $allSlaveTagInDBOfFoundMaster');

              if (previousTagsCount != optimizedTags.length) {
                RfidC72Plugin.playSound;
                previousTagsCount = optimizedTags.length;
              }

              log('Found In Db Tags : $foundSlaveTagsOfFoundMaster');
              log('Not Found In Db Tags : $unfoundSlaveTagsOfFoundMaster');
              if (foundMaster == '') {
                for (TagEpc tag in newTags) {
                  for (OptimizedTagBoxScan ot in optimizedTags) {
                    if (tag == ot.originalTag) {
                      if (ot.originalDBTag.isMaster() == true) {
                        foundMaster = ot.originalDBTag.pn;
                        log('Event DB Tags is = ${event.dbTags}');
                        allSlaveTagInDBOfFoundMaster = event.dbTags
                            .where((dbtag) => dbtag.selectedBox == foundMaster)
                            .toSet();
                        log('************2 AllSlaveTagsInDBOfFoundMaster = $allSlaveTagInDBOfFoundMaster');
                        allSlaveTagInDBOfFoundMasterLenght =
                            allSlaveTagInDBOfFoundMaster.length;
                        unfoundSlaveTagsOfFoundMaster =
                            Set.from(allSlaveTagInDBOfFoundMaster);
                        setPower('30');
                        log('Found Master is : $foundMaster');
                        return BoxCheckScanning(
                          tags: newTags,
                          foundMaster: foundMaster,
                          optimizedTags: optimizedTags,
                          foundSlaveTagsOfFoundMaster:
                              foundSlaveTagsOfFoundMaster,
                          foundSlaveTagsOfOtherMasters:
                              foundSlaveTagsOfOtherMasters,
                          allSlaveTagInDBOfFoundMaster:
                              allSlaveTagInDBOfFoundMaster,
                          allSlaveTagInDBOfFoundMasterLenght:
                              allSlaveTagInDBOfFoundMasterLenght,
                          unfoundSlaveTagsOfFoundMaster:
                              unfoundSlaveTagsOfFoundMaster,
                        );
                      }
                    }
                  }
                }
                if (newTags.isNotEmpty) {
                  return BoxCheckMasterNotFoundYet();
                }
              } else {
                return BoxCheckScanning(
                  tags: newTags,
                  foundMaster: foundMaster,
                  optimizedTags: optimizedTags,
                  foundSlaveTagsOfFoundMaster: foundSlaveTagsOfFoundMaster,
                  foundSlaveTagsOfOtherMasters: foundSlaveTagsOfOtherMasters,
                  allSlaveTagInDBOfFoundMaster: allSlaveTagInDBOfFoundMaster,
                  allSlaveTagInDBOfFoundMasterLenght:
                      allSlaveTagInDBOfFoundMasterLenght,
                  unfoundSlaveTagsOfFoundMaster: unfoundSlaveTagsOfFoundMaster,
                );
              }
              return BoxCheckIdle();
            },
            onError: (error, stackTrace) {
              log('Error: $error');
              return BoxCheckError();
            },
          );
        } catch (e) {
          log('Error starting continuous scan: $e');
        }
      }
    });

    on<BoxCheckStop>((event, emit) async {
      await RfidC72Plugin.stop;
      if (state is BoxCheckScanning) {
        final s = state as BoxCheckScanning;
        emit(BoxCheckScanning(
          tags: s.tags,
          foundMaster: s.foundMaster,
          optimizedTags: s.optimizedTags,
          foundSlaveTagsOfFoundMaster: s.foundSlaveTagsOfFoundMaster,
          foundSlaveTagsOfOtherMasters: s.foundSlaveTagsOfOtherMasters,
          allSlaveTagInDBOfFoundMaster: s.allSlaveTagInDBOfFoundMaster,
          allSlaveTagInDBOfFoundMasterLenght:
              s.allSlaveTagInDBOfFoundMasterLenght,
          unfoundSlaveTagsOfFoundMaster: s.unfoundSlaveTagsOfFoundMaster,
        ));
      }
    });

    on<BoxCheckFilter>((event, emit) async {
      if (state is BoxCheckScanning) {
        final s = state as BoxCheckScanning;
        emit(BoxCheckScanning(
          tags: s.tags,
          foundMaster: s.foundMaster,
          optimizedTags: s.optimizedTags,
          foundSlaveTagsOfFoundMaster: s.foundSlaveTagsOfFoundMaster,
          foundSlaveTagsOfOtherMasters: s.foundSlaveTagsOfOtherMasters,
          allSlaveTagInDBOfFoundMaster: s.allSlaveTagInDBOfFoundMaster,
          selectedFilter: event.filter,
          allSlaveTagInDBOfFoundMasterLenght:
              s.allSlaveTagInDBOfFoundMasterLenght,
          unfoundSlaveTagsOfFoundMaster: s.unfoundSlaveTagsOfFoundMaster,
        ));
      }
    });
  }

  // This function is created to use async operation in emit.foreach
  void setPower(String setPowerLevel) async {
    bool? isPowerSetOk = false;
    bool? isStarted = false;
    try {
      isStarted = await RfidC72Plugin.isStarted;
      log('isStarted at first = $isStarted');
      final isStopScan = await RfidC72Plugin.stop;
      isStarted = await RfidC72Plugin.isStarted;
      log('isStarted = $isStarted');
      if (isStopScan == true && isStarted == false) {
        log('isClosed and setting the level');
        isPowerSetOk = await RfidC72Plugin.setPowerLevel(setPowerLevel);
        log('Setting Power After Close : $isPowerSetOk');
        final getPowerLevel = await RfidC72Plugin.getPowerLevel;
        log('Power Level = $getPowerLevel');
      }

      if (isPowerSetOk == true) {
        final isContinue = await RfidC72Plugin.startContinuous;
        log('Restarted again : $isContinue');
      }
    } catch (e) {
      log('set Power Error ${e.toString()}');
    }
  }
}
