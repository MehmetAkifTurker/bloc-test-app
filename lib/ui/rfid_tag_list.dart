import 'package:bloc_test_app/data/models/db_tag.dart';

import 'package:flutter/material.dart';

class RfidTagListTile extends StatelessWidget {
  final DBTag tag;
  const RfidTagListTile({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'ID : ${tag.id}',
        ),
        const SizedBox(
          width: 5.0,
        ),
        Text(
          'EPC : ${tag.epc}',
        ),
        const SizedBox(
          width: 5.0,
        ),
        Text(tag.pn),
        const SizedBox(
          width: 5.0,
        ),
        Text(tag.sn),
        const SizedBox(
          width: 5.0,
        ),
      ],
    );
  }
}
