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

  const AppSettings({
    this.defaultQuality = ExportQuality.standard,
    this.defaultEnhancement = EnhancementMode.auto,
    this.autoCapture = true,
    this.blurDetection = true,
    this.darkMode = false,
    this.pageSize = 'A4',
    this.language = 'English',
  });

  AppSettings copyWith({
    ExportQuality? defaultQuality,
    EnhancementMode? defaultEnhancement,
    bool? autoCapture,
    bool? blurDetection,
    bool? darkMode,
    String? pageSize,
    String? language,
  }) => AppSettings(
    defaultQuality: defaultQuality ?? this.defaultQuality,
    defaultEnhancement: defaultEnhancement ?? this.defaultEnhancement,
    autoCapture: autoCapture ?? this.autoCapture,
    blurDetection: blurDetection ?? this.blurDetection,
    darkMode: darkMode ?? this.darkMode,
    pageSize: pageSize ?? this.pageSize,
    language: language ?? this.language,
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
