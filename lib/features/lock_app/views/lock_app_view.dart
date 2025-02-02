import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/features/lock_app/view_models/lock_app_view_model.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockAppView extends StatelessWidget {
  const LockAppView({super.key, required this.isPinAlreadySet});
  final bool isPinAlreadySet;
  @override
  Widget build(BuildContext context) {
    return Consumer<LockAppViewModel>(
      builder: (context, lockAppViewModel, child) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            isPinAlreadySet
                ? "Unlock Application"
                : lockAppViewModel.activeStep == 0
                    ? 'Set a Secure PIN'
                    : 'Confirm Your PIN',
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
                    : const SizedBox(width: 0, height: 120),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                TextField(
                  controller: lockAppViewModel.activeStep == 0
                      ? lockAppViewModel.pinController
                      : lockAppViewModel.confirmPinController,
                  obscureText: true,
                  maxLength: pinCodeLength,
                  autofocus: true,
                  showCursor: false,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: lockAppViewModel.activeStep == 0
                        ? 'Enter $pinCodeLength-Digit PIN'
                        : 'Confirm $pinCodeLength-Digit PIN',
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
                  btnTitle: lockAppViewModel.activeStep == 0 ? "Next" : "Save",
                  callBackFun: () => lockAppViewModel.updateStepIndex(
                      context, isPinAlreadySet),
                )
              ],
            ),
          ),
        ),
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
              maxReachedStep: 1,
              lineStyle: const LineStyle(
                lineLength: 100,
                lineSpace: 4,
                lineType: LineType.normal,
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
              internalPadding: 10,
              showLoadingAnimation: true,
              steps: [
                EasyStep(
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  title: 'Set PIN',
                  enabled: lockAppViewModel.activeStep == 0,
                ),
                EasyStep(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  title: 'Confirm PIN',
                  enabled: lockAppViewModel.activeStep == 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
