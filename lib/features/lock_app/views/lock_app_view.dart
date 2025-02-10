import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/lock_app/view_models/lock_app_view_model.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LockAppView extends StatefulWidget {
  LockAppView(
      {super.key,
      this.uninstallApp,
      required this.isPinAlreadySet,
      this.setAppLockPin,
      this.appIconImage,
      this.selectedPackageName,
      this.isUnLockScreen,
      required this.callBack,
      this.selectedMapAppName});
  final bool isPinAlreadySet;
  final Uint8List? appIconImage;
  final String? selectedPackageName;
  final bool? uninstallApp;
  final bool? isUnLockScreen;
  final String? selectedMapAppName;
  bool? setAppLockPin;
  Function callBack;

  @override
  State<LockAppView> createState() => _LockAppViewState();
}

class _LockAppViewState extends State<LockAppView> {
  final FocusNode _focusNode = FocusNode();
  // Define focus node
  @override
  void initState() {
    Provider.of<LockAppViewModel>(context, listen: false).setActiveStep = 0;
    Provider.of<LockAppViewModel>(context, listen: false).pinController.clear();
    Provider.of<LockAppViewModel>(context, listen: false)
        .confirmPinController
        .clear();
    Provider.of<LockAppViewModel>(context, listen: false).pinController.clear();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // Request focus after frame rendering
    });
    return Consumer<LockAppViewModel>(
      builder: (context, lockAppViewModel, child) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: const Text(""),
          centerTitle: true,
          title: Text(
            widget.uninstallApp ?? false
                ? "Enter Password to Uninstall App"
                : widget.setAppLockPin ?? false
                    ? "Set a Secure Password"
                    : widget.isPinAlreadySet
                        ? "Unlock Application"
                        : lockAppViewModel.activeStep == 0
                            ? 'Set a Secure Password'
                            : 'Confirm Your Password',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                !widget.isPinAlreadySet
                    ? _steps(lockAppViewModel)
                    : widget.setAppLockPin ?? false
                        ? _appLockSteps(lockAppViewModel, context)
                        : const SizedBox(width: 0, height: 120),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                TextField(
                  focusNode: _focusNode, // Set focus node
                  controller: lockAppViewModel.activeStep == 0
                      ? lockAppViewModel.pinController
                      : lockAppViewModel.activeStep == 2
                          ? lockAppViewModel.uninstallPinController
                          : lockAppViewModel.activeStep == 3
                              ? lockAppViewModel.uninstallConfirmPinController
                              : lockAppViewModel.confirmPinController,
                  obscureText: true,
                  maxLength: pinCodeLength,
                  autofocus: true,
                  showCursor: false,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: widget.setAppLockPin ?? false
                        ? 'Enter $pinCodeLength-Digit Password'
                        : lockAppViewModel.activeStep == 0 ||
                                lockAppViewModel.activeStep == 1
                            ? 'Enter $pinCodeLength-Digit Password'
                            : 'Confirm $pinCodeLength-Digit Password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextButton(
                    btnTitle: lockAppViewModel.activeStep == 0 ||
                            lockAppViewModel.activeStep == 3
                        ? "Next"
                        : "Save",
                    callBackFun: () async {
                      FirebaseLogger.logEvent("lockAppViewBtn", parameters: {
                        "step": lockAppViewModel.activeStep.toString(),
                        "btn_title": lockAppViewModel.activeStep == 0 ||
                                lockAppViewModel.activeStep == 3
                            ? "Next"
                            : "Save",
                        "app_name": widget.selectedMapAppName ?? "",
                        "selected_package_name":
                            widget.selectedPackageName ?? ""
                      });
                      if (widget.isUnLockScreen ?? false) {
                        List<String>? lockedAppList =
                            await getPrefStringList(locked_app_list) ?? [];

                        lockAppViewModel.verifyEnteredPinForAppUnlocking(
                            context,
                            widget.selectedMapAppName ?? "",
                            lockedAppList);
                      } else {
                        lockAppViewModel.updateStepIndex(
                            context,
                            widget.isPinAlreadySet,
                            widget.setAppLockPin ?? false,
                            widget.selectedPackageName ?? "",
                            widget.selectedMapAppName ?? "",
                            () => widget.callBack());
                      }
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appLockSteps(
      LockAppViewModel lockAppViewModel, BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 15,
            child: EasyStepper(
              activeStep: lockAppViewModel.activeStep,
              maxReachedStep: 2,
              lineStyle: const LineStyle(
                lineLength: 100,
                lineSpace: 8,
                lineType: LineType.dashed,
                unreachedLineColor: Colors.white54,
                finishedLineColor: Colors.white,
                activeLineColor: Colors.white,
              ),
              activeStepBorderColor: Colors.white,
              activeStepIconColor: Colors.white,
              activeStepTextColor: Colors.white,
              activeStepBackgroundColor: Colors.black,
              unreachedStepBackgroundColor: Colors.white54,
              unreachedStepBorderColor: Colors.white54,
              unreachedStepIconColor: Colors.white54,
              unreachedStepTextColor: Colors.white54,
              finishedStepBorderColor: Colors.white54,
              finishedStepIconColor: Colors.white54,
              finishedStepTextColor: Colors.white,
              borderThickness: 5,
              internalPadding: 20,
              showLoadingAnimation: true,
              steps: [
                EasyStep(
                  customTitle: const Text(
                      style: TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      "Set Primary App Password"),
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  //  title: 'Set Primary App Password',
                  enabled: lockAppViewModel.activeStep == 0,
                ),
                EasyStep(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  customTitle: const Text(
                      style: TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      'Set Secondary App Password'),
                  title: 'Set Secondary App Password',
                  enabled: lockAppViewModel.activeStep == 1,
                ),
                EasyStep(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  customTitle: const SizedBox(
                    width: 50,
                    child: Text(
                        maxLines: 2,
                        style: TextStyle(color: Colors.white, fontSize: 11),
                        textAlign: TextAlign.center,
                        'Secondary Uninstall Password'),
                  ),
                  title: 'Secondary Uninstall Password',
                  enabled: lockAppViewModel.activeStep == 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps(LockAppViewModel lockAppViewModel) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 15,
            child: EasyStepper(
              activeStep: lockAppViewModel.activeStep,
              maxReachedStep: 3,
              lineStyle: const LineStyle(
                lineLength: 100,
                lineSpace: 8,
                lineType: LineType.dashed,
                unreachedLineColor: Colors.white54,
                finishedLineColor: Colors.white,
                activeLineColor: Colors.white,
              ),
              activeStepBorderColor: Colors.white,
              activeStepIconColor: Colors.white,
              activeStepTextColor: Colors.white,
              activeStepBackgroundColor: Colors.black,
              unreachedStepBackgroundColor: Colors.white54,
              unreachedStepBorderColor: Colors.white54,
              unreachedStepIconColor: Colors.white54,
              unreachedStepTextColor: Colors.white54,
              finishedStepBorderColor: Colors.white54,
              finishedStepIconColor: Colors.white54,
              finishedStepTextColor: Colors.white,
              borderThickness: 7,
              internalPadding: 20,
              showLoadingAnimation: true,
              steps: [
                EasyStep(
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  title: 'Set Password',
                  enabled: lockAppViewModel.activeStep == 0,
                ),
                EasyStep(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  title: 'Confirm Password',
                  enabled: lockAppViewModel.activeStep == 1,
                ),
                EasyStep(
                  icon:
                      const Icon(Icons.delete_sweep_sharp, color: Colors.white),
                  title: 'Set Uninstall Password',
                  enabled: lockAppViewModel.activeStep == 2,
                ),
                EasyStep(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  title: 'Confirm Uninstall Password',
                  enabled: lockAppViewModel.activeStep == 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
