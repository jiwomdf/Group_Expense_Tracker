import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/app/apps/app_home.dart';
import 'package:group_expense_tracker/presentation/bloc/logout/logout_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/usermodel/userdatamodel_bloc.dart';
import 'package:group_expense_tracker/presentation/page/holiday/holiday_page.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/profile_widget.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';
import 'package:group_expense_tracker/util/version_util.dart';

class RightDrawer extends StatefulWidget {
  const RightDrawer({super.key});

  @override
  State<RightDrawer> createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  String _username = "";
  bool _isLight = false;

  @override
  void initState() {
    super.initState();
    context.read<UserDataModelBloc>().add(const GetUserDataModelEvent());
    if (mounted) {
      final appHome = AppHome.of(context);
      final isDarkMode = appHome.getIsDarkMode();
      Future.microtask(() => isDarkMode).then((value) {
        setState(() {
          _isLight = !value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: BlocBuilder<UserDataModelBloc, UserDataModelState>(
            builder: (context, state) {
          if (state is UserDataModelLoading) {
            const Center(child: CircularProgressIndicator());
          } else if (state is UserDataModelHasData) {
            _username = state.result.getDisplayName();
          } else if (state is UserDataModelError) {}

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topDrawer(),
                    switcher(context),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading("Features"),
                      _holiday(context),
                      _heading("Data Management"),
                      _exportData(context),
                      _heading("Setting Firebase"),
                      _settingFirebaseData(context),
                      _importData(context),
                      _updateTable(context),
                      _heading("Account"),
                      _logout(context),
                      _version(context)
                    ],
                  ),
                )
              ],
            ),
          );
        }));
  }

  Container topDrawer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Color.fromARGB(255, 132, 156, 242),
              Color(0xFF00968a)
            ]),
      ),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
      child: ProfileWidget(userName: _username),
    );
  }

  Padding _settingFirebaseData(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      child: InkWell(
        onTap: () {
          /** WidgetsBinding.instance.addPostFrameCallback((_) {
            //await preferences.clear();
            Phoenix.rebirth(context);
          }); **/
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.settings),
              ),
              Text("Setting Firebase",
                  style: TextUtil(context)
                      .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Padding _importData(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      child: InkWell(
        onTap: () {
          context.show("Currently feature not available");
          /**Navigator.pushNamed(context, ImportExpensePage.routeName);**/
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.file_upload),
              ),
              Text("Import Data",
                  style: TextUtil(context)
                      .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Padding _exportData(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      child: InkWell(
        onTap: () {
          context.show("Currently feature not available");
          /**Navigator.pushNamed(context, ExportExpensePage.routeName);**/
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.sd_storage_rounded),
              ),
              Text("Export Data",
                  style: TextUtil(context)
                      .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget switcher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Switch(
          activeTrackColor: AppColors.purple.purpleGradienVideo,
          inactiveTrackColor: AppColors.purple.purpleDarker,
          activeColor: _isLight
              ? AppColors.purple.purpleSoftLight
              : AppColors.purple.purpleSoftLight,
          value: _isLight,
          onChanged: (value) {
            _setTheme(AppHome.of(context), value);
          }),
    );
  }

  Padding _logout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 10),
      child: InkWell(
        onTap: () {
          context.read<LogoutBloc>().add(const GetLogoutEvent());
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.logout, color: AppColors.red.primary),
              ),
              Text("Logout",
                  style: TextUtil(context).urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _updateTable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      child: InkWell(
        onTap: () {
          context.show("Currently feature not available");
          /**Navigator.pushNamed(context, UpdateTablePage.routeName);**/
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.update),
              ),
              Text("Update Scheme",
                  style: TextUtil(context)
                      .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _version(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          "Version ${VersionUtil.version}",
          style: TextStyle(color: AppColors.grey.lightGray),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  _holiday(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, HolidayPage.routeName);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.sports_baseball_outlined),
              ),
              Text("Holiday",
                  style: TextUtil(context)
                      .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String s) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Text(s,
          style: TextUtil(context).plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  void _setTheme(AppHomeState appHome, bool value) {
    setState(() {
      _isLight = value;
    });
    if (_isLight) {
      appHome.changeTheme(ThemeMode.light);
    } else {
      appHome.changeTheme(ThemeMode.dark);
    }
  }
}
