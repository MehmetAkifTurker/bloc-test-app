import 'dart:developer';

import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:bloc_test_app/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/data/models/optimized_tag_rfid_scan.dart';
import 'package:bloc_test_app/data/models/tag_epc.dart';
import 'package:bloc_test_app/ui/router/app_bar.dart';
import 'package:bloc_test_app/ui/router/bottom_navigation.dart';
import 'package:bloc_test_app/ui/widgets/button_with_text_and_value.dart';
import 'package:bloc_test_app/ui/widgets/list_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RfidScanTagListScreen extends StatelessWidget {
  RfidScanTagListScreen({super.key});
  final double minSliderValue = 5.0;
  final double maxSliderValue = 30.0;
  int divisions = 10;

  @override
  Widget build(BuildContext context) {
    context.read<RfidTagBloc>().add(RfidInit());
    context.read<DBTagBloc>().add(DBGetTags());
    final Set<DBTag> foundInDBTags = {};
    final Set<TagEpc> notFoundInDBTags = {};

    return BlocBuilder<DBTagBloc, DBTagState>(
      builder: (context, dbState) {
        return Scaffold(
          appBar: commonAppBar(context, 'Scan'),
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
                              foundInDBTags.clear();
                              notFoundInDBTags.clear();
                              context
                                  .read<RfidTagBloc>()
                                  .add(RfidScanStart(dbState.tags));
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
                              context.read<RfidTagBloc>().add(RfidScanStop());
                            } catch (e) {
                              log(e.toString());
                            }
                          },
                          child: const Text('Stop'),
                        ),
                        TextButton(
                          onPressed: () {
                            try {
                              context.read<RfidTagBloc>().add(RfidInit());
                            } catch (e) {
                              log(e.toString());
                            }
                          },
                          child: const Text('Change Level'),
                        ),
                      ],
                    ),
                    BlocBuilder<RfidTagBloc, RfidTagState>(
                      // buildWhen: (previous, current) {
                      //   final shouldRebuildTag =
                      //       shouldRebuild(previous.tags, current.tags);
                      //   final shouldRebuildButtonPressed =
                      //       previous.selectedFilter != current.selectedFilter;
                      //   return shouldRebuildButtonPressed || shouldRebuildTag;
                      // },
                      builder: (context, state) {
                        switch (state) {
                          case RfidIdle():
                            return const Center(
                              child: Column(
                                children: [
                                  Text('Initializing.'),
                                  CircularProgressIndicator.adaptive(),
                                ],
                              ),
                            );
                          case RfidInitializing():
                            return Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      const Text('Power'),
                                      Slider(
                                        value:
                                            double.parse(state.status.getPower),
                                        onChanged: (value) {},
                                        onChangeEnd: (value) {
                                          context.read<RfidTagBloc>().add(
                                              RfidSetPower(
                                                  powerLevel: (value.toInt())
                                                      .toString()));
                                        },
                                        min: minSliderValue,
                                        max: maxSliderValue,
                                        divisions: divisions,
                                        label: 'Set Power Level',
                                      ),
                                      Text('${state.status.getPower} / 30'),
                                    ],
                                  ),
                                  const Text('Succesfully initialized.'),
                                  // Text(
                                  //   state.status.formattedStatus,
                                  //   style: const TextStyle(fontSize: 10),
                                  // ),
                                ],
                              ),
                            );
                          case RfidScanning():
                            log('UI Created when state is started or stopped');
                            // final stopWatchCreatingOptimizedTag = Stopwatch();
                            // final optimizedTag = processRfidScanTags(state.tags,
                            //     dbState.tags, foundInDBTags, notFoundInDBTags);
                            // stopWatchCreatingOptimizedTag.stop();
                            // log('Elapsed time when stopWatchCreatingOptimizedTag created : ${stopWatchCreatingOptimizedTag.elapsed.toString()}');
                            return Expanded(
                              child: Column(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ButtonWithTextAndValue(
                                          title: 'Total',
                                          value: state.tags.length,
                                          isSelected: state.selectedFilter ==
                                              RfidFilter.all,
                                          selectedColor: Colors.amber[50],
                                          onTap: () {
                                            context.read<RfidTagBloc>().add(
                                                const RfidFilterTags(
                                                    RfidFilter.all));
                                          },
                                        ),
                                        ButtonWithTextAndValue(
                                          title: 'Known',
                                          value: state.foundInDBTags.length,
                                          isSelected: state.selectedFilter ==
                                              RfidFilter.saved,
                                          selectedColor: Colors.amber[50],
                                          onTap: () {
                                            context.read<RfidTagBloc>().add(
                                                const RfidFilterTags(
                                                    RfidFilter.saved));
                                          },
                                        ),
                                        ButtonWithTextAndValue(
                                          title: 'Unknown',
                                          value: state.notFoundInDBTags.length,
                                          isSelected: state.selectedFilter ==
                                              RfidFilter.newTags,
                                          selectedColor: Colors.amber[50],
                                          onTap: () {
                                            context.read<RfidTagBloc>().add(
                                                const RfidFilterTags(
                                                    RfidFilter.newTags));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child:
                                        state.selectedFilter == RfidFilter.all
                                            ? ListBuilder<OptimizedTagRfidScan>(
                                                items: state.optimizedTag)
                                            : state.selectedFilter ==
                                                    RfidFilter.saved
                                                ? ListBuilder<DBTag>(
                                                    items: state.foundInDBTags
                                                        .toList())
                                                : state.selectedFilter ==
                                                        RfidFilter.newTags
                                                    ? ListBuilder<TagEpc>(
                                                        items: state
                                                            .notFoundInDBTags
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
      },
    );
  }
}
