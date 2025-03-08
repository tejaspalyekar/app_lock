import 'dart:developer';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:app_lock/utils/app_data_cleaner_util.dart';
import 'package:app_lock/utils/custom_snackbars.dart';
import 'package:app_lock/utils/secure_app_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockAppViewModel extends ChangeNotifier {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _uninstallPinController = TextEditingController();
  final TextEditingController _uninstallConfirmPinController =
      TextEditingController();
  String installPass = "";
  String secondaryPass = "";
  int _activeStep = 0;
  // bool get itemUploadingState => _isItemUploadLoading;
  // Uint8List? get imageFilePath => _imageFile;

  TextEditingController get pinController => _pinController;

  TextEditingController get uninstallPinController => _uninstallPinController;

  TextEditingController get uninstallConfirmPinController =>
      _uninstallConfirmPinController;
  TextEditingController get confirmPinController => _confirmPinController;
  int get activeStep => _activeStep;
  set setActiveStep(value) => _activeStep = value;

  updateStepIndex(
      BuildContext context,
      bool isPinAlreadySet,
      bool isSetAppLock,
      String lockedPackageName,
      String mappedAppPackageName,
      Function callBack) {
    if (isSetAppLock || !isPinAlreadySet) {
      if (_activeStep == 1) {
        validatePinCode(context, isSetAppLock);
      } else if (_activeStep == 0 &&
          _pinController.text.length == pinCodeLength) {
        _activeStep = _activeStep + 1;
      } else if (_activeStep == 3) {
        validateUninstallPinCode(context);
      } else if (_activeStep == 2 &&
          (_uninstallPinController.text.length == pinCodeLength)) {
        if (_uninstallPinController.text == installPass) {
          CustomSnackBar().customAnimatedSnackBar(
              "Invalid Password",
              "Uninstall and app lock password cannot be same",
              AnimatedSnackBarType.error,
              context);
          return;
        }

        if (!isSetAppLock) {
          _activeStep = _activeStep + 1;
        } else {
          setSecurePin(
              context, lockedPackageName, mappedAppPackageName, callBack);
        }
      } else {
        CustomSnackBar().customAnimatedSnackBar(
            "Invalid Password",
            "Please Enter a $pinCodeLength Digit Password",
            AnimatedSnackBarType.error,
            context);
      }
    } else {
      verifyEnteredPin(context);
    }

    notifyListeners();
  }

  setSecurePin(BuildContext context, String lockeAppPackageName,
      String mapPackageName, Function callBack) async {
    if (secondaryPass == _uninstallPinController.text ||
        installPass == _uninstallPinController.text) {
      CustomSnackBar().customAnimatedSnackBar(
          "Invalid Password",
          "Please enter unique password for primary and secondary app",
          AnimatedSnackBarType.error,
          context);
      _activeStep = 1;
      _uninstallPinController.clear();
      _confirmPinController.clear();
      notifyListeners();
      return false;
    }
    List<String> lockedAppList = await getPrefStringList(locked_app_list) ?? [];
    lockedAppList.add(lockeAppPackageName);
    lockedAppList.add(mapPackageName);
    await setPrefStringList(locked_app_list, lockedAppList);
    //store app with all details pin,mappedpackagename,hidden true/false
    // Provider.of<LauncherViewModel>(context, listen: false)
    //     .removeHiddenApp(lockeAppPackageName);
    Provider.of<LauncherViewModel>(context, listen: false).refreshApps(context);
    //primary app pass: pincontroller & secondary app pass controller _confirmpincontroller
    // secondary app == hidden and primary app is visible on launcher
    await setPrefStringList(lockeAppPackageName, [
      installPass,
      mapPackageName,
      'true',
      _uninstallPinController.text
    ]); //secondary app
    await setPrefStringList(mapPackageName,
        [secondaryPass, lockeAppPackageName, 'false']); //primary app
    _activeStep = 0;
    _pinController.clear();
    _confirmPinController.clear();
    _uninstallPinController.clear();
    callBack();
    Navigator.of(context).pop();
  }

  verifyEnteredPinForAppUnlocking(BuildContext context, String packageName,
      List<String>? lockedAppList) async {
    List<String>? mappedAppDetails =
        await getPrefStringList(packageName) ?? []; //primary app
    if (mappedAppDetails.isNotEmpty) {
      String primaryAppPin = mappedAppDetails[0];
      String lockedPackageName = mappedAppDetails[1]; //secondary

      List<String>? lockedAppDetails =
          await getPrefStringList(lockedPackageName) ?? []; //secondary app
      String secondaryAppPin = lockedAppDetails[0];
      String uninstallPassword = lockedAppDetails[3];

      if (pinController.text == primaryAppPin) {
        _activeStep = 0;
        _pinController.clear();
        _confirmPinController.clear();
        Navigator.of(context).pop();
        SecureAppLauncher().launchSecureApp(packageName, true);
        //DeviceApps.openApp(packageName);
      } else if (pinController.text == secondaryAppPin) {
        _activeStep = 0;
        _pinController.clear();
        _confirmPinController.clear();
        Navigator.of(context).pop();
        SecureAppLauncher().launchSecureApp(lockedPackageName, true);
        // DeviceApps.openApp(lockedPackageName);
      } else if (pinController.text == uninstallPassword) {
        // CustomSnackBar().customAnimatedSnackBar(
        //     "Invalid Password",
        //     "Please enter valid password code",
        //     AnimatedSnackBarType.error,
        //     context);
        _activeStep = 0;
        _pinController.clear();
        _confirmPinController.clear();
        Navigator.of(context).pop();
        DeviceApps.uninstallApp(lockedPackageName);

        try {
          TargetAppDataCleaner.clearTargetAppData(lockedPackageName);
        } catch (e) {
          log(e.toString());
        }

        //uninstall locked package name wala app
        //clear uninstalled app from local storage
      }
    }
  }

  verifyEnteredPin(BuildContext context) async {
    String storedPin = await getPrefString(app_lock_pin) ?? "";
    String uninstallPin = await getPrefString(app_uninstall_pin) ?? "";
    if (_pinController.text.length == pinCodeLength) {
      if (_pinController.text == storedPin) {
        FirebaseLogger.logEvent("verifyEnteredPin");
        pushReplacement(context, "/galleryScreen");
        // CustomSnackBar().customIconSnackBar(
        //     "Welcome Back!!", context, SnackBarType.success);
        _activeStep = 0;
        _pinController.clear();
        _confirmPinController.clear();
        notifyListeners();
        return true;
      } else if (pinController.text == uninstallPin) {
        await DeviceApps.uninstallApp("com.gallery.app_lock");
        return;
      }
    }
    CustomSnackBar().customAnimatedSnackBar(
        "Invalid Password",
        "Please enter valid password code",
        AnimatedSnackBarType.error,
        context);
    _activeStep = 0;
    _pinController.clear();
    _confirmPinController.clear();
    notifyListeners();
    return false;
  }

  validateUninstallPinCode(BuildContext context) async {
    String pin = await getPrefString(app_lock_pin);
    if (_uninstallConfirmPinController.text == pin) {
      _activeStep = 2;
      _uninstallPinController.clear();
      _uninstallConfirmPinController.clear();
      CustomSnackBar().customAnimatedSnackBar(
          "Invalid Password",
          "Uninstall and app lock password cannot be same",
          AnimatedSnackBarType.error,
          context);
      notifyListeners();
      return false;
    } else {
      if (_uninstallPinController.text.length == pinCodeLength &&
          _uninstallConfirmPinController.text.length == pinCodeLength) {
        if (_uninstallPinController.text ==
            _uninstallConfirmPinController.text) {
          FirebaseLogger.logEvent("uninstallPinValidation",
              parameters: {"is_pin_set": "true"});
          await setPrefBool(is_pin_set, true);
          await setPrefString(
              app_uninstall_pin, _uninstallConfirmPinController.text);
          pushReplacement(context, "/galleryScreen");
          // CustomSnackBar().customIconSnackBar(
          //     "Password Saved Successfully!!", context, SnackBarType.success);
          _activeStep = 0;
          _uninstallPinController.clear();
          _uninstallConfirmPinController.clear();
          notifyListeners();
          return true;
        }
      }
    }

    CustomSnackBar().customAnimatedSnackBar(
        "Password Mismatch",
        "Please enter a valid password which was used while creating password",
        AnimatedSnackBarType.error,
        context);
    _activeStep = 2;
    _uninstallPinController.clear();
    _uninstallConfirmPinController.clear();
    notifyListeners();
    return false;
  }

  validatePinCode(BuildContext context, bool isAppLock) async {
    if (_pinController.text.length == pinCodeLength &&
        _confirmPinController.text.length == pinCodeLength) {
      if (_pinController.text == _confirmPinController.text || isAppLock) {
        if (isAppLock && _pinController.text == _confirmPinController.text) {
          CustomSnackBar().customAnimatedSnackBar(
              "Invalid Password",
              "Please enter a unique password",
              AnimatedSnackBarType.error,
              context);
          _activeStep = 0;
          _pinController.clear();
          _confirmPinController.clear();
          notifyListeners();
          return;
        }
        if (!isAppLock) {
          await setPrefString(app_lock_pin, _confirmPinController.text);
        }

        _activeStep = _activeStep + 1;
        installPass = _confirmPinController.text;
        secondaryPass = _pinController.text;
        _pinController.clear();
        _confirmPinController.clear();

        notifyListeners();
        return true;
      }
    }
    CustomSnackBar().customAnimatedSnackBar(
        "Password Mismatch",
        "Please enter a valid password which was used while creating password",
        AnimatedSnackBarType.error,
        context);
    _activeStep = 0;
    _pinController.clear();
    _confirmPinController.clear();
    notifyListeners();
    return false;
  }
}
