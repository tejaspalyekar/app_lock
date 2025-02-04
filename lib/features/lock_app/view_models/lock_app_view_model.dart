import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/utils/custom_snackbars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class LockAppViewModel extends ChangeNotifier {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _uninstallPinController = TextEditingController();
  final TextEditingController _uninstallConfirmPinController =
      TextEditingController();
  int _activeStep = 0;
  // bool get itemUploadingState => _isItemUploadLoading;
  // Uint8List? get imageFilePath => _imageFile;

  TextEditingController get pinController => _pinController;

  TextEditingController get uninstallPinController => _uninstallPinController;

  TextEditingController get uninstallConfirmPinController =>
      _uninstallConfirmPinController;
  TextEditingController get confirmPinController => _confirmPinController;
  int get activeStep => _activeStep;

  updateStepIndex(
      BuildContext context,
      bool isPinAlreadySet,
      bool isSetAppLock,
      String lockedPackageName,
      String mappedAppPackageName,
      Function callBack) {
    if (isSetAppLock || !isPinAlreadySet) {
      if (_activeStep == 1) {
        validatePinCode(context, isSetAppLock, lockedPackageName,
            mappedAppPackageName, callBack);
      } else if (_activeStep == 0 &&
          _pinController.text.length == pinCodeLength) {
        _activeStep = _activeStep + 1;
      } else if (_activeStep == 3) {
        validateUninstallPinCode(context);
      } else if (_activeStep == 2 &&
          _uninstallPinController.text.length == pinCodeLength) {
        _activeStep = _activeStep + 1;
      } else {
        CustomSnackBar().customAnimatedSnackBar(
            "Invalid PIN",
            "Please Enter a $pinCodeLength Digit PIN",
            AnimatedSnackBarType.error,
            context);
      }
    } else {
      verifyEnteredPin(context);
    }

    notifyListeners();
  }

  verifyEnteredPin(BuildContext context) async {
    String storedPin = await getPrefString(app_lock_pin) ?? "";
    if (_pinController.text.length == pinCodeLength) {
      if (_pinController.text == storedPin) {
        pushReplacement(context, "/galleryScreen");
        CustomSnackBar().customIconSnackBar(
            "Welcome Back!!", context, SnackBarType.success);
        _activeStep = 0;
        _pinController.clear();
        _confirmPinController.clear();
        notifyListeners();
        return true;
      }
    }
    CustomSnackBar().customAnimatedSnackBar("Invalid PIN",
        "Please enter valid pin code", AnimatedSnackBarType.error, context);
    _activeStep = 0;
    _pinController.clear();
    _confirmPinController.clear();
    notifyListeners();
    return false;
  }

  validateUninstallPinCode(BuildContext context) async {
    if (_uninstallPinController.text.length == pinCodeLength &&
        _uninstallConfirmPinController.text.length == pinCodeLength) {
      if (_uninstallPinController.text == _uninstallConfirmPinController.text) {
        await setPrefBool(is_pin_set, true);
        await setPrefString(
            app_uninstall_pin, _uninstallConfirmPinController.text);
        pushReplacement(context, "/galleryScreen");
        CustomSnackBar().customIconSnackBar(
            "Pin Saved Successfully!!", context, SnackBarType.success);
        _activeStep = 0;
        _uninstallPinController.clear();
        _uninstallConfirmPinController.clear();
        notifyListeners();
        return true;
      }
    }
    CustomSnackBar().customAnimatedSnackBar(
        "Pin Mismatch",
        "Please enter a valid pin which was used while creating pin",
        AnimatedSnackBarType.error,
        context);
    _activeStep = 2;
    _uninstallPinController.clear();
    _uninstallConfirmPinController.clear();
    notifyListeners();
    return false;
  }

  validatePinCode(
      BuildContext context,
      bool isSetAppLock,
      String lockeAppPackageName,
      String mapPackageName,
      Function callBack) async {
    if (_pinController.text.length == pinCodeLength &&
        _confirmPinController.text.length == pinCodeLength) {
      if (_pinController.text == _confirmPinController.text) {
        if (isSetAppLock) {
          List<String> lockedAppList =
              await getPrefStringList(locked_app_list) ?? [];
          lockedAppList.add(lockeAppPackageName);
          lockedAppList.add(mapPackageName);
          await setPrefStringList(locked_app_list, lockedAppList);
          //store app with all details pin,mappedpackagename,hidden true/false
          await setPrefStringList(lockeAppPackageName,
              [_confirmPinController.text, mapPackageName, 'true']);
          await setPrefStringList(mapPackageName,
              [_confirmPinController.text, lockeAppPackageName, 'false']);
          _activeStep = 0;
          _pinController.clear();
          _confirmPinController.clear();
          callBack();
          Navigator.of(context).pop();
        } else {
          await setPrefString(app_lock_pin, _confirmPinController.text);
          _activeStep = _activeStep + 1;
          _pinController.clear();
          _confirmPinController.clear();
        }
        notifyListeners();
        return true;
      }
    }
    CustomSnackBar().customAnimatedSnackBar(
        "Pin Mismatch",
        "Please enter a valid pin which was used while creating pin",
        AnimatedSnackBarType.error,
        context);
    _activeStep = 0;
    _pinController.clear();
    _confirmPinController.clear();
    notifyListeners();
    return false;
  }
}
