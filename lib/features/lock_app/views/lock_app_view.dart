import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/features/lock_app/view_models/lock_app_view_model.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LockAppView extends StatelessWidget {
  LockAppView(
      {super.key,
      required this.isPinAlreadySet,
      this.setAppLockPin,
      this.appIconImage,
      this.selectedPackageName,
      required this.callBack,
      this.selectedMapAppName});
  final bool isPinAlreadySet;
  final Uint8List? appIconImage;
  final String? selectedPackageName;
  final String? selectedMapAppName;
  bool? setAppLockPin;
  Function callBack;
  final FocusNode _focusNode = FocusNode(); // Define focus node
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
            setAppLockPin ?? false
                ? "Set a Secure Password"
                : isPinAlreadySet
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
                !isPinAlreadySet
                    ? _steps(lockAppViewModel)
                    : setAppLockPin ?? false
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
                    hintText: lockAppViewModel.activeStep == 0 ||
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
                  callBackFun: () => lockAppViewModel.updateStepIndex(
                      context,
                      isPinAlreadySet,
                      setAppLockPin ?? false,
                      selectedPackageName ?? "",
                      selectedMapAppName ?? "",
                      () => callBack()),
                )
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
              maxReachedStep: 1,
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
