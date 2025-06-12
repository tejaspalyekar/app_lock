import 'package:flutter/material.dart';

class LauncherIndexViewModel extends ChangeNotifier {
  int currentPage = 1;
  double dragStartValue = 0;
  double dragEndValue = 0;
  double downDragStartValue = 0;
  double downDragEndValue = 0;

    bool get isDownDragEnabled => (downDragEndValue > downDragStartValue &&
      (downDragEndValue - downDragStartValue) > 70);
  bool get isDragEnabled =>
      (dragEndValue < dragStartValue && (dragStartValue - dragEndValue) > 20);


  updateLauncherViewIndex(int idx) {
    int oldIndex = currentPage;
    currentPage = idx;
    if (idx == 0 || (idx == 1 && oldIndex < 1)) {
      notifyListeners();
    }
  }
}
