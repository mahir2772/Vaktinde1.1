/// Alt menü sekmeleri (alt menüdeki sırayla)
enum MainTab { home, quran, qibla, zikir, tools }

/// Sekme içindeki ekranlardan (ör. ana ekranın Kur'an kartı) sekme geçişi.
/// MainWrapper kendini bağlar; çerçeve yoksa (testler, tek ekran) false.
class MainTabRequests {
  MainTabRequests._();

  static bool Function(MainTab tab)? _handler;

  static void attach(bool Function(MainTab tab) handler) => _handler = handler;

  static void detach(bool Function(MainTab tab) handler) {
    if (_handler == handler) _handler = null;
  }

  /// Sekmeye geçildiyse true
  static bool show(MainTab tab) => _handler?.call(tab) ?? false;
}
