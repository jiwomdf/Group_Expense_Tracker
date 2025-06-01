import 'package:bloc/bloc.dart';
import 'package:core/data/pref/firebase_options_pref.dart';
import 'package:core/domain/model/firebase_options_android_model.dart';
import 'package:core/domain/model/firebase_options_ios_model.dart';
import 'package:core/domain/model/firebase_options_web_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'setting_firebase_event.dart';
part 'setting_firebase_state.dart';

class SettingFirebaseBloc
    extends Bloc<SettingFirebaseEvent, SettingFirebaseState> {
  final FirebaseOptionsPref _firebaseOptionsPref;

  SettingFirebaseBloc(this._firebaseOptionsPref)
      : super(SettingFirebaseInitial()) {
    on<GetSettingFirebaseAndroidEvent>((event, emit) async {
      var data = await _firebaseOptionsPref.getFirebaseOptionsModelAndroid();

      switch (data.status) {
        case Status.success:
          if (data.data != null) {
            final nonNullData = data.data as FirebaseOptionsAndroidModel;
            emit(SettingFirebaseAndroidHasData(nonNullData));
          } else {
            emit(SettingFirebaseInitial());
          }
          break;
        case Status.error:
          emit(SettingFirebaseInitial());
          break;
      }
    });

    on<SetSettingFirebaseAndroidEvent>((event, emit) async {
      var result = await _firebaseOptionsPref
          .setFirebaseOptionsModelAndroid(event.firebaseOptionsAndroidModel);

      if (result) {
        emit(SettingFirebaseUpdated());
      }
    });

    on<GetSettingFirebaseIOSEvent>((event, emit) async {
      var data = await _firebaseOptionsPref.getFirebaseOptionsModeliOS();

      switch (data.status) {
        case Status.success:
          if (data.data != null) {
            final nonNullData = data.data as FirebaseOptionsIOSModel;
            emit(SettingFirebaseIOSHasData(nonNullData));
          } else {
            emit(SettingFirebaseInitial());
          }
          break;
        case Status.error:
          emit(SettingFirebaseInitial());
          break;
      }
    });

    on<SetSettingFirebaseIOSEvent>((event, emit) async {
      var result = await _firebaseOptionsPref
          .setFirebaseOptionsModeliOS(event.firebaseOptionsIOSModel);

      if (result) {
        emit(SettingFirebaseUpdated());
      }
    });

    on<GetSettingFirebaseWebEvent>((event, emit) async {
      var data = await _firebaseOptionsPref.getFirebaseOptionsModelWeb();

      switch (data.status) {
        case Status.success:
          if (data.data != null) {
            final nonNullData = data.data as FirebaseOptionsWebModel;
            emit(SettingFirebaseWebHasData(nonNullData));
          } else {
            emit(SettingFirebaseInitial());
          }
          break;
        case Status.error:
          emit(SettingFirebaseInitial());
          break;
      }
    });

    on<SetSettingFirebaseWebEvent>((event, emit) async {
      var result = await _firebaseOptionsPref
          .setFirebaseOptionsModelWeb(event.firebaseOptionsWebModel);

      if (result) {
        emit(SettingFirebaseUpdated());
      }
    });
  }
}
