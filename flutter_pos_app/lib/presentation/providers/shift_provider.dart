import 'package:flutter/material.dart';
import '../../data/models/shift_model.dart';
import '../../data/repositories/shift_repository.dart';

class ShiftProvider with ChangeNotifier {
  final ShiftRepository _shiftRepository = ShiftRepository();
  ShiftModel? _currentShift;
  bool _isLoading = false;
  Map<String, dynamic>? _lastCloseSummary;

  ShiftModel? get currentShift => _currentShift;
  bool get hasActiveShift => _currentShift != null && _currentShift!.status == 'open';
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastCloseSummary => _lastCloseSummary;

  Future<void> checkCurrentShift() async {
    _isLoading = true;
    notifyListeners();
    _currentShift = await _shiftRepository.getCurrentShift();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> openShift(double startingCash) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentShift = await _shiftRepository.openShift(startingCash);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> closeShift(double endingCash, String? notes) async {
    _isLoading = true;
    notifyListeners();
    try {
      final summary = await _shiftRepository.closeShift(endingCash, notes);
      _lastCloseSummary = summary;
      _currentShift = null;
      return summary;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
