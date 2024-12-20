import 'dart:developer';

import 'package:bloc_test_app/business_logic/blocs/box_check/box_check_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/ui/router/app_bar.dart';
import 'package:bloc_test_app/ui/router/bottom_navigation.dart';

import 'package:bloc_test_app/ui/widgets/button_with_text_and_value.dart';
import 'package:bloc_test_app/ui/widgets/list_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoxCheckListScreen extends StatelessWidget {
  BoxCheckListScreen({super.key});
  final double minSliderValue = 5.0;
  final double maxSliderValue = 30.0;
  int divisions = 10;

  @override
  Widget build(BuildContext context) {
    context.read<BoxCheckBloc>().add(BoxCheckInit());
    context.read<DBTagBloc>().add(DBGetTags());

    return BlocBuilder<DBTagBloc, DBTagState>(
      builder: (context, dbState) {
        return BlocBuilder<BoxCheckBloc, BoxCheckState>(
            builder: (context, boxCheckState) {
          return Scaffold(
            appBar: commonAppBar(context, 'Box Check'),
            bottomNavigationBar: bottomNavigationBar(context),
            //drawer: commonDrawer(context),
            body: dbState is DBTagLoaded
                ? Column(
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              try {
                                context
                                    .read<BoxCheckBloc>()
                                    .add(BoxCheckStart(dbState.tags));
                              } catch (e) {
                                log(e.toString());
                              }
                            },
                            child: const Text('Read'),
                          ),
                          // child: Badge(
                          //   backgroundColor: Colors.blueAccent,
                          //   label: Text(
                          //     state.tags.length.toString(),
                          //   ),
                          //   child: const Text('Read'),
                          // )),
                          TextButton(
                            onPressed: () {
                              try {
                                context
                                    .read<BoxCheckBloc>()
                                    .add(BoxCheckStop());
                              } catch (e) {
                                log(e.toString());
                              }
                            },
                            child: const Text('Stop'),
                          ),
                          TextButton(
                            onPressed: () {
                              try {
                                context
                                    .read<BoxCheckBloc>()
                                    .add(BoxCheckInit());
                              } catch (e) {
                                log(e.toString());
                              }
                            },
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                      BlocListener<BoxCheckBloc, BoxCheckState>(
                        listener: (context, state) {
                          log('----------------BoxCheckBloc state is = ${state.toString()}');
                        },
                        child: const SizedBox.shrink(),
                      ),
                      BlocListener<DBTagBloc, DBTagState>(
                        listener: (context, state) {
                          log('-------------------DBTagBloc state is = ${state.toString()}');
                        },
                        child: const SizedBox.shrink(),
                      ),
                      BlocBuilder<BoxCheckBloc, BoxCheckState>(
                        // buildWhen: (previous, current) {
                        //   final shouldRebuildTag =
                        //       shouldRebuild(previous.tags, current.tags);
                        //   final shouldRebuildButtonPressed =
                        //       previous.selectedFilter != current.selectedFilter;
                        //   return shouldRebuildButtonPressed || shouldRebuildTag;
                        // },
                        builder: (context, state) {
                          switch (state) {
                            case BoxCheckIdle():
                              return const Center(
                                child: Column(
                                  children: [
                                    Text('Initializing.'),
                                    CircularProgressIndicator.adaptive(),
                                  ],
                                ),
                              );
                            case BoxCheckInitializing():
                              return const Center(
                                child: Column(
                                  children: [
                                    // Row(
                                    //   mainAxisAlignment:
                                    //       MainAxisAlignment.center,
                                    //   mainAxisSize: MainAxisSize.max,
                                    //   children: [
                                    //     const Text('Power'),
                                    //     Slider(
                                    //       value: double.parse(
                                    //           state.status.getPower),
                                    //       onChanged: (value) {},
                                    //       onChangeEnd: (value) {
                                    //         context.read<BoxCheckBloc>().add(
                                    //             BoxCheckSetPower(
                                    //                 powerLevel: (value.toInt())
                                    //                     .toString()));
                                    //       },
                                    //       min: minSliderValue,
                                    //       max: maxSliderValue,
                                    //       divisions: divisions,
                                    //       label: 'Set Power Level',
                                    //     ),
                                    //     Text('${state.status.getPower} / 30'),
                                    //   ],
                                    // ),
                                    Text('Succesfully initialized.'),
                                    // Text(
                                    //   state.status.formattedStatus,
                                    //   style: const TextStyle(fontSize: 10),
                                    // ),
                                  ],
                                ),
                              );
                            case BoxCheckMasterNotFoundYet():
                              return const Text(
                                  'Master Tag can not be found. Keep scanning');
                            case BoxCheckScanning():
                              log('UI Created when state is started or stopped');
                              final stopWatchCreatingOptimizedTag = Stopwatch();
                              // final optimizedTag = processTags(
                              //     state.tags,
                              //     dbState.tags,
                              //     foundInDBTags,
                              //     notFoundInDBTags);

                              stopWatchCreatingOptimizedTag.stop();
                              log('Elapsed time when stopWatchCreatingOptimizedTag created : ${stopWatchCreatingOptimizedTag.elapsed.toString()}');
                              return Expanded(
                                child: Column(
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Column(
                                        children: [
                                          Text(
                                            state.foundMaster,
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                          Row(
                                            children: [
                                              ButtonWithTextAndValue(
                                                title: 'Total',
                                                value: state
                                                    .allSlaveTagInDBOfFoundMasterLenght,
                                                isSelected:
                                                    state.selectedFilter ==
                                                        FilterBoxCheck
                                                            .foundBoxTotalTools,
                                                selectedColor: Colors.amber[50],
                                                onTap: () {
                                                  context
                                                      .read<BoxCheckBloc>()
                                                      .add(const BoxCheckFilter(
                                                          FilterBoxCheck
                                                              .foundBoxTotalTools));
                                                  log(state
                                                      .allSlaveTagInDBOfFoundMaster
                                                      .toString());
                                                },
                                              ),
                                              ButtonWithTextAndValue(
                                                title: 'Found',
                                                value: state
                                                    .foundSlaveTagsOfFoundMaster
                                                    .length,
                                                // secondValue: state
                                                //     .allSlaveTagInDBOfFoundMasterLenght,
                                                isSelected:
                                                    state.selectedFilter ==
                                                        FilterBoxCheck
                                                            .foundBoxFoundTools,
                                                selectedColor: Colors.amber[50],
                                                onTap: () {
                                                  log(state
                                                      .foundSlaveTagsOfFoundMaster
                                                      .toString());
                                                  context
                                                      .read<BoxCheckBloc>()
                                                      .add(const BoxCheckFilter(
                                                          FilterBoxCheck
                                                              .foundBoxFoundTools));
                                                },
                                              ),
                                              ButtonWithTextAndValue(
                                                title: 'Missing',
                                                value: state
                                                    .unfoundSlaveTagsOfFoundMaster
                                                    .length,
                                                isSelected: state
                                                        .selectedFilter ==
                                                    FilterBoxCheck
                                                        .foundBoxUnfoundTools,
                                                selectedColor: Colors.amber[50],
                                                onTap: () {
                                                  log(state
                                                      .foundSlaveTagsOfFoundMaster
                                                      .toString());
                                                  context
                                                      .read<BoxCheckBloc>()
                                                      .add(const BoxCheckFilter(
                                                          FilterBoxCheck
                                                              .foundBoxUnfoundTools));
                                                },
                                              ),
                                              ButtonWithTextAndValue(
                                                title: 'Other Box Tags',
                                                value: state
                                                    .foundSlaveTagsOfOtherMasters
                                                    .length,
                                                isSelected: state
                                                        .selectedFilter ==
                                                    FilterBoxCheck
                                                        .otherBoxesFoundTools,
                                                selectedColor: Colors.amber[50],
                                                onTap: () {
                                                  log(state
                                                      .foundSlaveTagsOfOtherMasters
                                                      .toString());
                                                  context
                                                      .read<BoxCheckBloc>()
                                                      .add(const BoxCheckFilter(
                                                          FilterBoxCheck
                                                              .otherBoxesFoundTools));
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: state.selectedFilter ==
                                              FilterBoxCheck
                                                  .foundBoxUnfoundTools
                                          ? ListBuilder<DBTag>(
                                              items: state
                                                  .unfoundSlaveTagsOfFoundMaster
                                                  .toList())
                                          : state.selectedFilter ==
                                                  FilterBoxCheck
                                                      .foundBoxFoundTools
                                              ? ListBuilder<DBTag>(
                                                  items: state
                                                      .foundSlaveTagsOfFoundMaster
                                                      .toList())
                                              : state.selectedFilter ==
                                                      FilterBoxCheck
                                                          .otherBoxesFoundTools
                                                  ? ListBuilder<DBTag>(
                                                      items: state
                                                          .foundSlaveTagsOfOtherMasters
                                                          .toList())
                                                  : state.selectedFilter ==
                                                          FilterBoxCheck
                                                              .foundBoxTotalTools
                                                      ? ListBuilder<DBTag>(
                                                          items: state
                                                              .allSlaveTagInDBOfFoundMaster
                                                              .toList())
                                                      : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              );

                            default:
                          }
                          return Container();
                        },
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      children: [
                        Text('Initializing.'),
                        CircularProgressIndicator.adaptive(),
                      ],
                    ),
                  ),
          );
        });
      },
    );
  }
}
