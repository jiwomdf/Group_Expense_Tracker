import 'package:core/domain/model/firebase_options_android_model.dart';
import 'package:core/domain/model/firebase_options_ios_model.dart';
import 'package:core/domain/model/firebase_options_web_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:group_expense_tracker/presentation/bloc/setting_firebase/setting_firebase_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/platform_util.dart';

/// Pre loaded data taken from the google-services.json of the
/// `money-expanse-lidya-s` firebase project, so the user does not have to
/// type every field manually.
class _FirebaseOptionsPreload {
  static const apiKey = "AIzaSyDbHjguTqUQTAcoe0Tv49lBDFSlh84wmJE";
  static const androidAppId = "1:543633010470:android:0f1d7f9f97bb305537dbe7";
  static const messagingSenderId = "543633010470";
  static const projectId = "money-expanse-lidya-s";
  static const storageBucket = "money-expanse-lidya-s.appspot.com";
  static const authDomain = "money-expanse-lidya-s.firebaseapp.com";
  static const packageName = "com.programmergabut.lidya_group_expan";
}

class SettingFirebasePage extends StatefulWidget {
  static const routeName = '/setting-firebase-page';
  const SettingFirebasePage({super.key});

  @override
  State<SettingFirebasePage> createState() => _SettingFirebasePageState();
}

class _SettingFirebasePageState extends State<SettingFirebasePage> {
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    if (PlatformUtil.isAndroid()) {
      context
          .read<SettingFirebaseBloc>()
          .add(const GetSettingFirebaseAndroidEvent());
    } else if (PlatformUtil.isIOS()) {
      context
          .read<SettingFirebaseBloc>()
          .add(const GetSettingFirebaseIOSEvent());
    } else if (kIsWeb) {
      context
          .read<SettingFirebaseBloc>()
          .add(const GetSettingFirebaseWebEvent());
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text("Firebase options setting",
                    style: TextUtil(context).plusJakarta(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      "inorder to connect the firebase project to this device, you need to copy the firebase options from the firebase console and paste it here.",
                      textAlign: TextAlign.justify,
                      style: TextUtil(context).plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                ),
                PlatformUtil.isAndroid()
                    ? androidWidget(context)
                    : const SizedBox(),
                PlatformUtil.isIOS() ? iosWidget(context) : const SizedBox(),
                kIsWeb ? webWidget(context) : const SizedBox(),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget androidWidget(BuildContext context) {
    TextEditingController firebaseNameController = TextEditingController();
    TextEditingController apiKeyController = TextEditingController();
    TextEditingController appIdController = TextEditingController();
    TextEditingController messagingSenderIdController = TextEditingController();
    TextEditingController projectIdController = TextEditingController();
    TextEditingController storageBucketController = TextEditingController();
    firebaseNameController.text = defaultFirebaseAppName;
    apiKeyController.text = _FirebaseOptionsPreload.apiKey;
    appIdController.text = _FirebaseOptionsPreload.androidAppId;
    messagingSenderIdController.text =
        _FirebaseOptionsPreload.messagingSenderId;
    projectIdController.text = _FirebaseOptionsPreload.projectId;
    storageBucketController.text = _FirebaseOptionsPreload.storageBucket;

    return BlocBuilder<SettingFirebaseBloc, SettingFirebaseState>(
      builder: (context, state) {
        if (state is SettingFirebaseInitial) {
        } else if (state is SettingFirebaseAndroidHasData) {
          firebaseNameController.text = state.firebaseOptionsModel.fName;
          apiKeyController.text = state.firebaseOptionsModel.apiKey;
          appIdController.text = state.firebaseOptionsModel.appId;
          messagingSenderIdController.text =
              state.firebaseOptionsModel.messagingSenderId;
          projectIdController.text = state.firebaseOptionsModel.projectId;
          storageBucketController.text =
              state.firebaseOptionsModel.storageBucket;
        } else if (state is SettingFirebaseUpdated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Phoenix.rebirth(context);
          });
        }

        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Android Firebase Setting",
                    style: TextUtil(context).plusJakarta(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Column(
                children: [
                  textFormStyle(
                    controller: firebaseNameController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "Firebase Name"),
                  ),
                  textFormStyle(
                    controller: apiKeyController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "apiKey"),
                  ),
                  textFormStyle(
                    controller: appIdController,
                    decoration:
                        textFormFieldStyle(context: context, hintText: "appId"),
                  ),
                  textFormStyle(
                    controller: messagingSenderIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "messagingSenderId"),
                  ),
                  textFormStyle(
                    controller: projectIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "projectId"),
                  ),
                  textFormStyle(
                    controller: storageBucketController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "storageBucket"),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<SettingFirebaseBloc>().add(
                                  SetSettingFirebaseAndroidEvent(
                                      FirebaseOptionsAndroidModel(
                                fName: firebaseNameController.text,
                                apiKey: apiKeyController.text,
                                appId: appIdController.text,
                                messagingSenderId:
                                    messagingSenderIdController.text,
                                projectId: projectIdController.text,
                                storageBucket: storageBucketController.text,
                              )));
                        }
                      },
                      child: const Text("Save Android Firebase Options")),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget iosWidget(BuildContext context) {
    TextEditingController firebaseNameController = TextEditingController();
    TextEditingController apiKeyController = TextEditingController();
    TextEditingController appIdController = TextEditingController();
    TextEditingController messagingSenderIdController = TextEditingController();
    TextEditingController projectIdController = TextEditingController();
    TextEditingController storageBucketController = TextEditingController();
    TextEditingController iosBundleIdController = TextEditingController();
    firebaseNameController.text = defaultFirebaseAppName;
    apiKeyController.text = _FirebaseOptionsPreload.apiKey;
    messagingSenderIdController.text =
        _FirebaseOptionsPreload.messagingSenderId;
    projectIdController.text = _FirebaseOptionsPreload.projectId;
    storageBucketController.text = _FirebaseOptionsPreload.storageBucket;
    iosBundleIdController.text = _FirebaseOptionsPreload.packageName;

    return BlocBuilder<SettingFirebaseBloc, SettingFirebaseState>(
      builder: (context, state) {
        if (state is SettingFirebaseInitial) {
        } else if (state is SettingFirebaseIOSHasData) {
          firebaseNameController.text = state.firebaseOptionsModel.fName;
          apiKeyController.text = state.firebaseOptionsModel.apiKey;
          appIdController.text = state.firebaseOptionsModel.appId;
          messagingSenderIdController.text =
              state.firebaseOptionsModel.messagingSenderId;
          projectIdController.text = state.firebaseOptionsModel.projectId;
          storageBucketController.text =
              state.firebaseOptionsModel.storageBucket;
          iosBundleIdController.text = state.firebaseOptionsModel.iosBundleId;
        } else if (state is SettingFirebaseUpdated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Phoenix.rebirth(context);
          });
        }

        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("iOS Firebase Setting",
                    style: TextUtil(context).plusJakarta(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Column(
                children: [
                  textFormStyle(
                    controller: firebaseNameController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "Firebase Name"),
                  ),
                  textFormStyle(
                    controller: apiKeyController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "apiKey"),
                  ),
                  textFormStyle(
                    controller: appIdController,
                    decoration:
                        textFormFieldStyle(context: context, hintText: "appId"),
                  ),
                  textFormStyle(
                    controller: messagingSenderIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "messagingSenderId"),
                  ),
                  textFormStyle(
                    controller: projectIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "projectId"),
                  ),
                  textFormStyle(
                    controller: storageBucketController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "storageBucket"),
                  ),
                  textFormStyle(
                    controller: iosBundleIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "iosBundleId"),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<SettingFirebaseBloc>().add(
                                  SetSettingFirebaseIOSEvent(
                                      FirebaseOptionsIOSModel(
                                fName: firebaseNameController.text,
                                apiKey: apiKeyController.text,
                                appId: appIdController.text,
                                messagingSenderId:
                                    messagingSenderIdController.text,
                                projectId: projectIdController.text,
                                storageBucket: storageBucketController.text,
                                iosBundleId: iosBundleIdController.text,
                              )));
                        }
                      },
                      child: const Text("Save iOS Firebase Options")),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget webWidget(BuildContext context) {
    TextEditingController firebaseNameController = TextEditingController();
    TextEditingController apiKeyController = TextEditingController();
    TextEditingController authDomainController = TextEditingController();
    TextEditingController projectIdController = TextEditingController();
    TextEditingController storageBucketController = TextEditingController();
    TextEditingController messagingSenderIdController = TextEditingController();
    TextEditingController appIdController = TextEditingController();
    TextEditingController measurementIdController = TextEditingController();
    firebaseNameController.text = defaultFirebaseAppName;
    apiKeyController.text = _FirebaseOptionsPreload.apiKey;
    authDomainController.text = _FirebaseOptionsPreload.authDomain;
    projectIdController.text = _FirebaseOptionsPreload.projectId;
    storageBucketController.text = _FirebaseOptionsPreload.storageBucket;
    messagingSenderIdController.text =
        _FirebaseOptionsPreload.messagingSenderId;

    return BlocBuilder<SettingFirebaseBloc, SettingFirebaseState>(
      builder: (context, state) {
        if (state is SettingFirebaseInitial) {
        } else if (state is SettingFirebaseWebHasData) {
          firebaseNameController.text = state.firebaseOptionsModel.fName;
          apiKeyController.text = state.firebaseOptionsModel.apiKey;
          authDomainController.text = state.firebaseOptionsModel.authDomain;
          projectIdController.text = state.firebaseOptionsModel.projectId;
          storageBucketController.text =
              state.firebaseOptionsModel.storageBucket;
          messagingSenderIdController.text =
              state.firebaseOptionsModel.messagingSenderId;
          appIdController.text = state.firebaseOptionsModel.appId;
          measurementIdController.text =
              state.firebaseOptionsModel.measurementId;
        } else if (state is SettingFirebaseUpdated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Phoenix.rebirth(context);
          });
        }

        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Web Firebase Setting",
                    style: TextUtil(context).plusJakarta(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              textFormStyle(
                controller: firebaseNameController,
                decoration: textFormFieldStyle(
                    context: context, hintText: "Firebase Name"),
              ),
              Column(
                children: [
                  textFormStyle(
                    controller: apiKeyController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "apiKey"),
                  ),
                  textFormStyle(
                    controller: authDomainController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "authDomain"),
                  ),
                  textFormStyle(
                    controller: projectIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "projectId"),
                  ),
                  textFormStyle(
                    controller: storageBucketController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "storageBucket"),
                  ),
                  textFormStyle(
                    controller: messagingSenderIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "messagingSenderId"),
                  ),
                  textFormStyle(
                    controller: appIdController,
                    decoration:
                        textFormFieldStyle(context: context, hintText: "appId"),
                  ),
                  textFormStyle(
                    controller: measurementIdController,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "measurementId"),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<SettingFirebaseBloc>().add(
                                  SetSettingFirebaseWebEvent(
                                      FirebaseOptionsWebModel(
                                fName: firebaseNameController.text,
                                apiKey: apiKeyController.text,
                                authDomain: authDomainController.text,
                                projectId: projectIdController.text,
                                storageBucket: storageBucketController.text,
                                messagingSenderId:
                                    messagingSenderIdController.text,
                                appId: appIdController.text,
                                measurementId: measurementIdController.text,
                              )));
                        }
                      },
                      child: const Text("Save Web Firebase Options")),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget textFormStyle({
    required TextEditingController controller,
    required InputDecoration decoration,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: TextFormField(
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return "Field cannot be empty, please check the firebase options in firebase for the value";
              }
              return null;
            },
        controller: controller,
        decoration: decoration,
      ),
    );
  }
}
