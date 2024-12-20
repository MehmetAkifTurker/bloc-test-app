import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/data/models/optimized_tag_box_scan.dart';
import 'package:bloc_test_app/data/models/tag_epc.dart';
import 'package:bloc_test_app/java_comm/rfid_c72_plugin.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_test_app/data/models/rfid_status.dart';

part 'box_check_event.dart';
part 'box_check_state.dart';

class BoxCheckBloc extends Bloc<BoxCheckEvent, BoxCheckState> {
  int previousTagsCount = 0;
  RfidStatus statusVariable = RfidStatus(
      connectingStatus: false,
      platformName: '',
      getPower: '',
      getTemperature: '',
      getFrequencyMode: '');

  BoxCheckBloc() : super(BoxCheckIdle()) {
    on<BoxCheckInit>(
      (event, emit) async {
        bool? result = false;
        previousTagsCount = 0;

        final isconnected = await RfidC72Plugin.isConnected;
        log('rfid_boxcheck_bloc - isConnected = ${isconnected.toString()}');
        if (isconnected == false) {
          result = await RfidC72Plugin.connect;
          log('rfid_boxcheck_bloc - connecting result = ${result.toString()}');
        }

        if (isconnected == true || result == true) {
          try {
            final isReading = await RfidC72Plugin.isStarted;
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
        statusVariable.connectingStatus = isconnected ?? false;
        final platformName = (isconnected == true || result == true)
            ? await RfidC72Plugin.platformVersion
            : 'Could not get the platform name';
        log('rfid_boxcheck_bloc - platform Name = $platformName');
        statusVariable.platformName = platformName!;

        try {
          await RfidC72Plugin.setPowerLevel('5');
        } catch (e) {
          log('rfid_boxcheck_bloc - Set Power Error ${e.toString()}');
        }

        try {
          final getPowerLevel = (isconnected == true || result == true)
              ? await RfidC72Plugin.getPowerLevel
              : 'Could not get power';
          log('rfid_boxcheck_bloc - get Power Level = $getPowerLevel');

          statusVariable.getPower = getPowerLevel ?? '';
        } catch (e) {
          log('rfid_boxcheck_bloc - Get Power Error ${e.toString()}');
        }
        try {
          final getTemperature = (isconnected == true || result == true)
              ? await RfidC72Plugin.getTemperature
              : 'Could not get temperature';

          statusVariable.getTemperature = getTemperature ?? '';

          log('rfid_boxcheck_bloc - get Temperature = $getTemperature');
        } catch (e) {
          log('rfid_boxcheck_bloc - Get Temperature ${e.toString()}');
        }

        try {
          final getFrequencyMode = (isconnected == true || result == true)
              ? await RfidC72Plugin.getFrequencyMode
              : 'Could not get frequency mode';

          statusVariable.getFrequencyMode = getFrequencyMode ?? '';

          log('rfid_boxcheck_bloc - get Frequency Mode = $getFrequencyMode');
        } catch (e) {
          log('rfid_boxcheck_bloc - Get Power Error ${e.toString()}');
        }

        try {
          final clearResult = await RfidC72Plugin.clearData;
          log('Clear result is = $clearResult');
        } catch (e) {
          log('Can not clear data = $e');
        }
        log('Status is $statusVariable');
        emit(BoxCheckInitializing(status: statusVariable));
      },
    );

    on<BoxCheckSetPower>(
      (event, emit) async {
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
        emit((BoxCheckInitializing(status: statusVariable)));
      },
    );

    on<BoxCheckStart>((event, emit) async {
      final isScanning = await RfidC72Plugin.isStarted;
      String foundMaster = '';
      Set<DBTag> foundSlaveTagsOfFoundMaster = {};
      Set<DBTag> unfoundSlaveTagsOfFoundMaster = {};
      Set<DBTag> foundSlaveTagsOfOtherMasters = {};
      Set<DBTag> allSlaveTagInDBOfFoundMaster = {};
      int allSlaveTagInDBOfFoundMasterLenght = 0;

      await RfidC72Plugin.clearData;
      foundSlaveTagsOfFoundMaster.clear;
      unfoundSlaveTagsOfFoundMaster.clear;
      foundSlaveTagsOfOtherMasters.clear;
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
              //Coming TagEPC from MethodChannel
              final newTags = TagEpc.parseTags(result);

              //OptimizedTag and Creating the lists.
              final optimizedTags = processBoxScanTags(
                tags: newTags,
                dbTags: event.dbTags,
                masterTagName: foundMaster,
                foundSlaveTagsOfFoundMaster: foundSlaveTagsOfFoundMaster,
                foundSlaveTagsOfOtherMaster: foundSlaveTagsOfOtherMasters,
                allSlaveTagInDBOfFoundMaster: allSlaveTagInDBOfFoundMaster,
                unfoundSlaveTagsOfFoundMaster: unfoundSlaveTagsOfFoundMaster,
              );

              log('************1 AllSlaveTagsInDBOfFoundMaster = ${allSlaveTagInDBOfFoundMaster.toString()}');

              if (previousTagsCount != optimizedTags.length) {
                RfidC72Plugin.playSound;
                previousTagsCount = optimizedTags.length;
              }

              log('Found In Db Tags : ${foundSlaveTagsOfFoundMaster.toString()}');
              log('Not Found In Db Tags : ${unfoundSlaveTagsOfFoundMaster.toString()}');
              if (foundMaster == '') {
                for (TagEpc tag in newTags) {
                  for (OptimizedTagBoxScan optimizedTag in optimizedTags) {
                    if (tag == optimizedTag.originalTag) {
                      if (optimizedTag.originalDBTag.isMaster() == true) {
                        foundMaster = optimizedTag.originalDBTag.pn;
                        // foundMasterTotalSlaveInDB = event.dbTags
                        //     .where((tag) => tag.selectedBox == foundMaster)
                        //     .length;
                        log('Event DB Tags is = ${event.dbTags}');
                        allSlaveTagInDBOfFoundMaster = event.dbTags
                            .where((tag) => tag.selectedBox == foundMaster)
                            .toSet();
                        log('************2 AllSlaveTagsInDBOfFoundMaster = ${allSlaveTagInDBOfFoundMaster.toString()}');
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
              // Handle error
              log('Error: $error');
              return BoxCheckError(); // Or any appropriate error state
            },
          );
        } catch (e) {
          // Handle startContinuous error
          log('Error starting continuous scan: $e');
          // Emit error state if needed
        }
      }
    });

    on<BoxCheckStop>((event, emit) async {
      await RfidC72Plugin.stop;
      if (state is BoxCheckScanning) {
        emit(BoxCheckScanning(
          tags: (state as BoxCheckScanning).tags,
          foundMaster: (state as BoxCheckScanning).foundMaster,
          optimizedTags: (state as BoxCheckScanning).optimizedTags,
          foundSlaveTagsOfFoundMaster:
              (state as BoxCheckScanning).foundSlaveTagsOfFoundMaster,
          foundSlaveTagsOfOtherMasters:
              (state as BoxCheckScanning).foundSlaveTagsOfOtherMasters,
          allSlaveTagInDBOfFoundMaster:
              (state as BoxCheckScanning).allSlaveTagInDBOfFoundMaster,
          allSlaveTagInDBOfFoundMasterLenght:
              (state as BoxCheckScanning).allSlaveTagInDBOfFoundMasterLenght,
          unfoundSlaveTagsOfFoundMaster:
              (state as BoxCheckScanning).unfoundSlaveTagsOfFoundMaster,
        ));
      }
    });

    on<BoxCheckFilter>((event, emit) async {
      if (state is BoxCheckScanning) {
        emit(BoxCheckScanning(
            tags: (state as BoxCheckScanning).tags,
            foundMaster: (state as BoxCheckScanning).foundMaster,
            optimizedTags: (state as BoxCheckScanning).optimizedTags,
            foundSlaveTagsOfFoundMaster:
                (state as BoxCheckScanning).foundSlaveTagsOfFoundMaster,
            foundSlaveTagsOfOtherMasters:
                (state as BoxCheckScanning).foundSlaveTagsOfOtherMasters,
            allSlaveTagInDBOfFoundMaster:
                (state as BoxCheckScanning).allSlaveTagInDBOfFoundMaster,
            selectedFilter: event.filter,
            allSlaveTagInDBOfFoundMasterLenght:
                (state as BoxCheckScanning).allSlaveTagInDBOfFoundMasterLenght,
            unfoundSlaveTagsOfFoundMaster:
                (state as BoxCheckScanning).unfoundSlaveTagsOfFoundMaster));
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
      // await Future.delayed(const Duration(seconds: 1));
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

        log('Restartted again : $isContinue');
      }
    } catch (e) {
      log('set Power Error ${e.toString()}');
    }
  }
}
