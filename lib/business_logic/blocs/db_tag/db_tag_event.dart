import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:equatable/equatable.dart';

abstract class DBTagEvent extends Equatable {
  const DBTagEvent();

  @override
  List<Object> get props => [];
}

class DBAddTag extends DBTagEvent {
  final DBTag tag;

  const DBAddTag({required this.tag});
}

class DBGetTags extends DBTagEvent {}

class DBGetMasterTags extends DBTagEvent {}

class DBDeleteTag extends DBTagEvent {
  final String uid;

  const DBDeleteTag({required this.uid});
}

class DBUpdateTag extends DBTagEvent {
  final String uid;
  final DBTag tag;

  const DBUpdateTag({required this.uid, required this.tag});
}

class DBGetTagsFiltered extends DBTagEvent {
  final String column;
  final String value;

  const DBGetTagsFiltered({required this.column, required this.value});
}
