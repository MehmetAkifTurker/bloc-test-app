import 'package:bloc_test_app/data/models/db_tag.dart';

import 'package:equatable/equatable.dart';

abstract class DBTagState extends Equatable {
  const DBTagState();

  @override
  List<Object> get props => [];
}

class DBTagInitial extends DBTagState {}

class DBTagLoading extends DBTagState {}

class DBTagLoaded extends DBTagState {
  final List<DBTag> tags;
  final Set<String> masters;

  const DBTagLoaded(this.tags, this.masters);

  @override
  List<Object> get props => [tags];
}

class DBTagError extends DBTagState {
  final String message;

  const DBTagError(this.message);
}
