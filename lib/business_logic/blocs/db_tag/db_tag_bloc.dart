import 'dart:developer';

import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:water_boiler_rfid_labeler/data/models/const.dart';
import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:water_boiler_rfid_labeler/data/repositories/rfid_tag_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DBTagBloc extends Bloc<DBTagEvent, DBTagState> {
  final RfidTagRepository _repository;

  DBTagBloc(
    this._repository,
  ) : super(DBTagInitial()) {
    on<DBGetTags>(
      (event, emit) async {
        emit(DBTagLoading());
        final stopwatch0 = Stopwatch()..start();
        final tags = await _repository.getTag();
        stopwatch0.stop();
        final stopwatch1 = Stopwatch()..start();
        final Set<String> masters = {};
        for (DBTag tag in tags) {
          if (tag.isMaster()) {
            masters.add(tag.pn);
          }
        }
        stopwatch1.stop();
        log('DB Tag Bloc - Getting all DB Time : ${stopwatch0.elapsed.toString()}');
        log('DB Tag Bloc - Filter with For Loop : ${stopwatch1.elapsed.toString()}');
        emit(DBTagLoaded(tags, masters));
      },
    );

    on<DBGetTagsFiltered>(
      (event, emit) async {
        emit(DBTagLoading());
        final stopwatch0 = Stopwatch()..start();
        final tags = await _repository.getTag();
        final List<DBTag> filteredTags = [];
        final Set<String> masters = {};
        for (DBTag tag in tags) {
          if (event.column == filterNone) {
          } else if (event.column == filterExpCheck) {
            if (tag.isExpired()) {
              filteredTags.add(tag);
            }
          } else {
            final mapTag = tag.toMap();
            if (mapTag[event.column]
                .toString()
                .toLowerCase()
                .contains(event.value.toLowerCase())) {
              filteredTags.add(tag);
            }
          }
          if (tag.isMaster()) {
            masters.add(tag.pn);
          }
        }
        stopwatch0.stop();
        log('DB Tag Bloc - Getting all DB Time : ${stopwatch0.elapsed.toString()}');
        emit(DBTagLoaded(filteredTags, masters));
      },
    );

    on<DBAddTag>(
      (event, emit) async {
        if (state is DBTagLoaded || state is DBTagInitial) {
          emit(DBTagLoading());
          try {
            await _repository.addTag(tag: event.tag);
            final tags = await _repository.getTag();
            final Set<String> masters = {};
            for (DBTag tag in tags) {
              if (tag.isMaster()) {
                masters.add(tag.pn);
              }
            }

            //final masters = await _repository.getmasters();
            emit(DBTagLoaded(tags, masters));
          } catch (e) {
            log('DB Tag Bloc -  When adding a tag this error accurs : ${e.toString()}');
            emit(DBTagError(e.toString()));
          }
        }
      },
    );
    on<DBDeleteTag>(
      (event, emit) async {
        if (state is DBTagLoaded) {
          emit(DBTagLoading());
          try {
            await _repository.deleteTag(uid: event.uid);
            final tags = await _repository.getTag();
            final Set<String> masters = {};
            for (DBTag tag in tags) {
              if (tag.isMaster()) {
                masters.add(tag.pn);
              }
            }
            // final masters = await _repository.getmasters();
            emit(DBTagLoaded(tags, masters));
          } catch (e) {
            log('DB Tag Bloc - When deleting a tag this error accurs : ${e.toString()}');
            emit(DBTagError(e.toString()));
          }
        }
      },
    );
    on<DBUpdateTag>(
      (event, emit) async {
        if (state is DBTagLoaded) {
          emit(DBTagLoading());
          try {
            await _repository.updateTag(uid: event.uid, tag: event.tag);
            final tags = await _repository.getTag();
            final Set<String> masters = {};
            for (DBTag tag in tags) {
              if (tag.isMaster()) {
                masters.add(tag.pn);
              }
            }

            // final masters = await _repository.getmasters();
            emit(DBTagLoaded(tags, masters));
          } catch (e) {
            log('DB Tag Bloc - When updating a tag this error accurs : ${e.toString()}');
            emit(DBTagError(e.toString()));
          }
        }
      },
    );
  }
}
