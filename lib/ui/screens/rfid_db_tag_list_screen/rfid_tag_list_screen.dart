import 'dart:developer';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/ui/router/app_bar.dart';
import 'package:bloc_test_app/ui/router/bottom_navigation.dart';
import 'package:bloc_test_app/ui/screens/rfid_db_tag_list_screen/_rfid_db_tag_list_filtering.dart';
import 'package:bloc_test_app/ui/widgets/list_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/variables.dart';

class RfidTagListScreen extends StatelessWidget {
  const RfidTagListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Database'),
      bottomNavigationBar: bottomNavigationBar(context),
      //drawer: commonDrawer(context),
      body: Column(
        children: [
          const FilteringSection(),
          Expanded(
            child: BlocBuilder<DBTagBloc, DBTagState>(
              builder: (context, state) {
                switch (state) {
                  case DBTagInitial():
                    log('RFID Tag List Screen - State is Initialize');
                    return const Center(
                        child: Text(
                            'Select filter criteria and press Filter button to see the tags in the database'));
                  //return const Center(child: CircularProgressIndicator());
                  case DBTagLoading():
                    log('RFID Tag List Screen - State is Loading');
                    return const Center(
                        child: Column(
                      children: [
                        Text('Tags are loading'),
                        CircularProgressIndicator(),
                      ],
                    ));
                  case DBTagLoaded():
                    // log('RFID Tag List Screen - State is Tag Loaded');
                    // log('RFID Tag List Screen - ${state.masters.toString()}');
                    // return ListView.builder(
                    //   itemCount: state.tags.length,
                    //   itemBuilder: (context, index) {
                    //     final tag = state.tags[index];
                    //     return buildDBTagListTile(context, index, tag);
                    //   },
                    // );
                    return Column(
                      children: [
                        Expanded(
                          child: ListBuilder<DBTag>(items: state.tags),
                        ),
                        Container(
                          color: listColorBackgroundExpired,
                          width: double.infinity,
                          child: Text(
                            'Total Tags for selected filter = ${state.tags.length.toString()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:
                                    listColorIconAndTextExpiredOrMasterNotAssigned),
                          ),
                        )
                      ],
                    );
                  //Text('Total Tags for selected filter = ${state.tags.length.toString()}')

                  default:
                    return const Text('Unknown State');
                }
              },
            ),
          ),
        ],
      ),
      //floatingActionButton: const RfidDBActinButtons(),
    );
  }
}

final createInitialRfidTag = DBTag(
    epc: 'epcTag',
    pn: 'pn',
    sn: 'sn',
    desc: 'desc',
    type: 'type',
    tagType: '2',
    selectedBox: 'Master 2',
    expDate: '',
    note: '');
