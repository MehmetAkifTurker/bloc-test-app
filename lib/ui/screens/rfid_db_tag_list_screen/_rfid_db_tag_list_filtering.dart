import 'dart:developer';
import 'package:bloc_test_app/business_logic/blocs/db_filtering_bloc/bloc/db_filtering_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:bloc_test_app/data/models/const.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilteringSection extends StatelessWidget {
  const FilteringSection({super.key});

  @override
  Widget build(BuildContext context) {
    String selectedBox = '';
    int selectedTagType = boxTagNo;
    FilteringStates selectedFilteringState = FilteringStates.none;
    TextEditingController filterCtrl = TextEditingController();
    return Container(
      margin: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  const Text('Filter Selection : '),
                  Expanded(
                    child: DropdownButtonFormField<FilteringStates>(
                      value: selectedFilteringState,
                      items: FilteringStates.values
                          .map((state) => DropdownMenuItem<FilteringStates>(
                                value: state,
                                child: Text(state.toString().split('.').last),
                              ))
                          .toList(),
                      onChanged: (newState) {
                        selectedFilteringState = newState!;
                        log('_Rfid DB Tag List Filtering - Filtering State is : ${selectedFilteringState.toString()}');
                        context.read<DbFilteringBloc>().add(
                            DbFilterSelectionEvent(
                                filteringStates: selectedFilteringState));
                      },
                    ),
                  ),
                  BlocBuilder<DbFilteringBloc, FilteringStates>(
                    builder: (context, filterState) {
                      return TextButton(
                        onPressed: () {
                          switch (filterState) {
                            case FilteringStates.none:
                              context.read<DBTagBloc>().add(DBGetTags());
                              break;
                            case FilteringStates.selectedBox:
                              context.read<DBTagBloc>().add(DBGetTagsFiltered(
                                  column: selectedFilteringState
                                      .toString()
                                      .split('.')
                                      .last,
                                  value: selectedBox));
                              log('_Rfid DB Tag List Filtering - Selected Box is : $selectedBox');
                            case FilteringStates.tagType:
                              context.read<DBTagBloc>().add(DBGetTagsFiltered(
                                  column: selectedFilteringState
                                      .toString()
                                      .split('.')
                                      .last,
                                  value: selectedTagType.toString()));
                              log(
                                '_Rfid DB Tag List Filtering - Filtering State Last String is : ${selectedFilteringState.toString().split('.').last}',
                              );

                            default:
                              context.read<DBTagBloc>().add(DBGetTagsFiltered(
                                  column: selectedFilteringState
                                      .toString()
                                      .split('.')
                                      .last,
                                  value: filterCtrl.text));
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.refresh),
                            Padding(padding: EdgeInsets.all(10)),
                            Text('Filter'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              BlocBuilder<DbFilteringBloc, FilteringStates>(
                builder: (context, filteringState) {
                  switch (filteringState) {
                    case FilteringStates.none:
                      // return const Row(
                      //   children: [
                      //     Text('No filter'),
                      //   ],
                      // );
                      return const SizedBox.shrink();
                    case FilteringStates.expCheck:
                      // return const Row(
                      //   children: [
                      //     Text('Expire Date Filter'),
                      //   ],
                      // );
                      return const SizedBox.shrink();
                    case FilteringStates.selectedBox:
                      return Row(
                        children: [
                          // Text(
                          //     'Filtering with ${selectedFilteringState.toString().split('.').last} : '),
                          // const SizedBox(
                          //   width: 10,
                          // ),
                          Expanded(
                            child: BlocBuilder<DBTagBloc, DBTagState>(
                              builder: (context, dbTagState) {
                                if (dbTagState is DBTagLoaded) {
                                  if (dbTagState.masters.isNotEmpty) {
                                    selectedBox == ''
                                        ? selectedBox = dbTagState.masters.first
                                        : null;
                                  }
                                  try {
                                    log('_Rfid DB Tag List Filtering - Selected Box is $selectedBox');
                                    log('_Rfid DB Tag List Filtering - Masters are : ${dbTagState.masters}');
                                    return DropdownButtonFormField<String>(
                                      value: dbTagState.masters
                                                  .contains(selectedBox) &&
                                              selectedBox != ''
                                          ? selectedBox
                                          : null,
                                      items: dbTagState.masters
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ))
                                          .toList(),
                                      decoration: const InputDecoration(
                                        helperText:
                                            'Select a box for filtering',
                                      ),
                                      onChanged: ((value) {
                                        selectedBox = value!;
                                        log('_Rfid DB Tag List Filtering - Selected Master is : $value');
                                        log('_Rfid DB Tag List Filtering - Master List is : ${dbTagState.masters.toString()}');
                                        // context
                                        //     .read<DbTagPopupCubit>()
                                        //     .changeVisibility(_selectedTagType);
                                        // if (value == boxTagNo) {}
                                      }),
                                    );
                                  } catch (e) {
                                    log('_Rfid DB Tag List Filtering - There is an error when creating dropdown box. ${e.toString()}');
                                    return const SizedBox.shrink();
                                  }
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    case FilteringStates.tagType:
                      return Row(
                        children: [
                          // Text(
                          //     'Filtering with ${selectedFilteringState.toString().split('.').last} : '),
                          // const SizedBox(
                          //   width: 10,
                          // ),
                          Expanded(
                            child: DropdownButtonFormField(
                              value: selectedTagType,
                              items: tagType
                                  .map((item) => DropdownMenuItem(
                                        value: item.keys.first,
                                        child: Text(item.values.first),
                                      ))
                                  .toList(),
                              decoration: const InputDecoration(
                                helperText:
                                    'Select the type for filtering (Box or Tool)',
                              ),
                              onChanged: ((value) {
                                selectedTagType = value!;
                                // context
                                //     .read<DbTagPopupCubit>()
                                //     .changeVisibility(_selectedTagType);
                              }),
                            ),
                          ),
                        ],
                      );
                    default:
                      return Row(
                        children: [
                          Text(
                              'Filtering with ${selectedFilteringState.toString().split('.').last} : '),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: filterCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'Enter filter criteria'),
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                        ],
                      );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
