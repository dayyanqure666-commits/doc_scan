import 'package:flutter/foundation.dart';
import '../models/scan_document.dart';
import 'storage_service.dart';

class AppSettings {
  final ExportQuality defaultQuality;
  final EnhancementMode defaultEnhancement;
  final bool autoCapture;
  final bool blurDetection;
  final bool darkMode;
  final String pageSize;
  final String language;
  
  // Preprocessing switches
  final bool enableAutoCrop;
  final bool enableDeskew;
  final bool enableNoiseReduction;
  final bool enableContrastEnhancement;
  final bool enableSharpening;
  final bool enableBackgroundCleanup;
  final bool enableGrayscale;
  final bool enableThresholding;

  const AppSettings({
    this.defaultQuality = ExportQuality.standard,
    this.defaultEnhancement = EnhancementMode.auto,
    this.autoCapture = true,
    this.blurDetection = true,
    this.darkMode = false,
    this.pageSize = 'A4',
    this.language = 'English',
    this.enableAutoCrop = true,
    this.enableDeskew = true,
    this.enableNoiseReduction = true,
    this.enableContrastEnhancement = true,
    this.enableSharpening = true,
    this.enableBackgroundCleanup = true,
    this.enableGrayscale = true,
    this.enableThresholding = true,
  });

  bool get hasAnyPreprocessingEnabled =>
      enableAutoCrop ||
      enableDeskew ||
      enableNoiseReduction ||
      enableContrastEnhancement ||
      enableSharpening ||
      enableBackgroundCleanup ||
      enableGrayscale ||
      enableThresholding;

  AppSettings copyWith({
    ExportQuality? defaultQuality,
    EnhancementMode? defaultEnhancement,
    bool? autoCapture,
    bool? blurDetection,
    bool? darkMode,
    String? pageSize,
    String? language,
    bool? enableAutoCrop,
    bool? enableDeskew,
    bool? enableNoiseReduction,
    bool? enableContrastEnhancement,
    bool? enableSharpening,
    bool? enableBackgroundCleanup,
    bool? enableGrayscale,
    bool? enableThresholding,
  }) => AppSettings(
    defaultQuality: defaultQuality ?? this.defaultQuality,
    defaultEnhancement: defaultEnhancement ?? this.defaultEnhancement,
    autoCapture: autoCapture ?? this.autoCapture,
    blurDetection: blurDetection ?? this.blurDetection,
    darkMode: darkMode ?? this.darkMode,
    pageSize: pageSize ?? this.pageSize,
    language: language ?? this.language,
    enableAutoCrop: enableAutoCrop ?? this.enableAutoCrop,
    enableDeskew: enableDeskew ?? this.enableDeskew,
    enableNoiseReduction: enableNoiseReduction ?? this.enableNoiseReduction,
    enableContrastEnhancement: enableContrastEnhancement ?? this.enableContrastEnhancement,
    enableSharpening: enableSharpening ?? this.enableSharpening,
    enableBackgroundCleanup: enableBackgroundCleanup ?? this.enableBackgroundCleanup,
    enableGrayscale: enableGrayscale ?? this.enableGrayscale,
    enableThresholding: enableThresholding ?? this.enableThresholding,
  );
}

class ScanSession {
  final String sessionId;
  final List<String> capturedPaths;
  final List<String> processedPaths;
  int currentPageIndex;

  ScanSession({
    required this.sessionId,
    List<String>? capturedPaths,
    List<String>? processedPaths,
    this.currentPageIndex = 0,
  })  : capturedPaths = capturedPaths ?? [],
        processedPaths = processedPaths ?? [];
}

class AppStateProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<ScanDocument> _documents = [];
  AppSettings _settings = const AppSettings();
  ScanSession? _currentSession;
  bool _isLoading = false;
  String? _error;
  int _storageBytes = 0;

  // Getters
  List<ScanDocument> get documents => List.unmodifiable(_documents);
  AppSettings get settings => _settings;
  ScanSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get storageBytes => _storageBytes;

  // ── Initialization ────────────────────────────────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      _documents = await _storage.getAllDocuments();
      _storageBytes = await _storage.getTotalStorageBytes();
      
      // Load settings
      final autoCropVal = await _storage.getSetting('enable_auto_crop');
      final deskewVal = await _storage.getSetting('enable_deskew');
      final noiseRedVal = await _storage.getSetting('enable_noise_reduction');
      final contrastVal = await _storage.getSetting('enable_contrast_enhancement');
      final sharpeningVal = await _storage.getSetting('enable_sharpening');
      final bgCleanupVal = await _storage.getSetting('enable_background_cleanup');
      final grayscaleVal = await _storage.getSetting('enable_grayscale');
      final thresholdingVal = await _storage.getSetting('enable_thresholding');
      
      final autoCaptureVal = await _storage.getSetting('auto_capture');
      final blurDetectionVal = await _storage.getSetting('blur_detection');
      final pageSizeVal = await _storage.getSetting('page_size');
      final defaultEnhancementVal = await _storage.getSetting('default_enhancement');
      final defaultQualityVal = await _storage.getSetting('default_quality');
      final darkModeVal = await _storage.getSetting('dark_mode');
      
      _settings = AppSettings(
        enableAutoCrop: autoCropVal == null ? true : autoCropVal == 'true',
        enableDeskew: deskewVal == null ? true : deskewVal == 'true',
        enableNoiseReduction: noiseRedVal == null ? true : noiseRedVal == 'true',
        enableContrastEnhancement: contrastVal == null ? true : contrastVal == 'true',
        enableSharpening: sharpeningVal == null ? true : sharpeningVal == 'true',
        enableBackgroundCleanup: bgCleanupVal == null ? true : bgCleanupVal == 'true',
        enableGrayscale: grayscaleVal == null ? true : grayscaleVal == 'true',
        enableThresholding: thresholdingVal == null ? true : thresholdingVal == 'true',
        
        autoCapture: autoCaptureVal == null ? true : autoCaptureVal == 'true',
        blurDetection: blurDetectionVal == null ? true : blurDetectionVal == 'true',
        pageSize: pageSizeVal ?? 'A4',
        defaultEnhancement: defaultEnhancementVal == null 
            ? EnhancementMode.auto 
            : EnhancementMode.values.firstWhere((e) => e.name == defaultEnhancementVal, orElse: () => EnhancementMode.auto),
        defaultQuality: defaultQualityVal == null 
            ? ExportQuality.standard 
            : ExportQuality.values.firstWhere((q) => q.name == defaultQualityVal, orElse: () => ExportQuality.standard),
        darkMode: darkModeVal == null ? false : darkModeVal == 'true',
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Documents ─────────────────────────────────────────────
  Future<void> addDocument(ScanDocument doc) async {
    await _storage.saveDocument(doc);
    final index = _documents.indexWhere((d) => d.id == doc.id);
    if (index != -1) {
      _documents[index] = doc;
    } else {
      _documents.insert(0, doc);
    }
    _storageBytes = await _storage.getTotalStorageBytes();
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    await _storage.deleteDocument(id);
    _documents.removeWhere((d) => d.id == id);
    _storageBytes = await _storage.getTotalStorageBytes();
    notifyListeners();
  }

  Future<void> renameDocument(String id, String newName) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    doc.name = newName;
    await _storage.updateDocument(doc);
    notifyListeners();
  }

  Future<void> updateDocumentPDF(String id, String pdfPath) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    doc.pdfPath = pdfPath;
    await _storage.updateDocument(doc);
    notifyListeners();
  }

  List<ScanDocument> searchDocuments(String query) {
    if (query.isEmpty) return _documents;
    return _documents
        .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<ScanDocument> get recentDocuments =>
      _documents.take(5).toList();

  // ── Session ───────────────────────────────────────────────
  void startSession(String sessionId) {
    _currentSession = ScanSession(sessionId: sessionId);
    notifyListeners();
  }

  void addPageToSession(String originalPath, String processedPath) {
    _currentSession?.capturedPaths.add(originalPath);
    _currentSession?.processedPaths.add(processedPath);
    notifyListeners();
  }

  void clearSession() {
    _currentSession = null;
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────
  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _storage.saveSetting('enable_auto_crop', newSettings.enableAutoCrop.toString());
    _storage.saveSetting('enable_deskew', newSettings.enableDeskew.toString());
    _storage.saveSetting('enable_noise_reduction', newSettings.enableNoiseReduction.toString());
    _storage.saveSetting('enable_contrast_enhancement', newSettings.enableContrastEnhancement.toString());
    _storage.saveSetting('enable_sharpening', newSettings.enableSharpening.toString());
    _storage.saveSetting('enable_background_cleanup', newSettings.enableBackgroundCleanup.toString());
    _storage.saveSetting('enable_grayscale', newSettings.enableGrayscale.toString());
    _storage.saveSetting('enable_thresholding', newSettings.enableThresholding.toString());
    
    _storage.saveSetting('auto_capture', newSettings.autoCapture.toString());
    _storage.saveSetting('blur_detection', newSettings.blurDetection.toString());
    _storage.saveSetting('page_size', newSettings.pageSize);
    _storage.saveSetting('default_enhancement', newSettings.defaultEnhancement.name);
    _storage.saveSetting('default_quality', newSettings.defaultQuality.name);
    _storage.saveSetting('dark_mode', newSettings.darkMode.toString());
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
