import 'dart:developer';

import 'package:bloc_test_app/java_comm/rfid_c72_plugin.dart';
import 'package:bloc_test_app/ui/router/app_bar.dart';
import 'package:flutter/material.dart';

import '../../../data/models/variables.dart';
import '../../router/bottom_navigation.dart';

class TagWriteScreen extends StatelessWidget {
  const TagWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TextEditingController accessPwd = TextEditingController();
    // TextEditingController bank = TextEditingController();
    // TextEditingController ptr = TextEditingController();
    TextEditingController data = TextEditingController();
    data.text = globalDataToWriteTag;
    return Scaffold(
      appBar: commonAppBar(context, 'Write to Tag'),
      bottomNavigationBar: bottomNavigationBar(context),
      body: Center(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const Text(
                'writeData Function Parameters',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // TextFormField(
              //   controller: accessPwd,
              //   decoration:
              //       const InputDecoration(hintText: 'Access pasword - String'),
              //   keyboardType: TextInputType.multiline,
              // ),
              // TextFormField(
              //   controller: bank,
              //   decoration: const InputDecoration(hintText: 'Bank - int'),
              //   keyboardType: TextInputType.multiline,
              // ),
              // TextFormField(
              //   controller: ptr,
              //   decoration: const InputDecoration(hintText: 'Pointer - int'),
              //   keyboardType: TextInputType.multiline,
              // ),
              TextFormField(
                controller: data,
                decoration: const InputDecoration(hintText: 'Data - String'),
                //keyboardType: TextInputType.multiline,
                onEditingComplete: () {
                  globalDataToWriteTag = data.text;
                  log(globalDataToWriteTag);
                },
              ),
              TextButton(
                onPressed: () async {
                  log(data.text);
                  await RfidC72Plugin.writeTag2(data.text);
                },
                child: const Text('Execute writeData'),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
