import 'package:flutter/widgets.dart';

/// Okuyucu listesinde ayet taşıyan öge (sayfa, meal sayfası ya da ayet
/// kartı): kaydırma durunca görünen ilk ayeti ve bir ayetin öge içindeki
/// konumunu verir. Ögenin State'i uygular.
abstract interface class AyahLocator {
  BuildContext get context;
  bool get mounted;

  /// Ögenin üstünden [dy] aşağıdaki satırdaki ayet
  int ayahAt(double dy);

  /// Ayetin öge içindeki üst konumu (dp); ögenin ilk ayetinde 0
  double offsetOf(int ayah);
}

/// Ekranda kurulu ögelerin kaydı (liste dizini → öge); okuyucu görünen ilk
/// ayeti ve atlanacak konumu buradan bulur
class ReaderItemRegistry {
  final Map<int, AyahLocator> _items = {};

  void attach(int index, AyahLocator item) => _items[index] = item;

  void detach(int index, AyahLocator item) {
    if (identical(_items[index], item)) _items.remove(index);
  }

  AyahLocator? operator [](int index) => _items[index];

  Iterable<AyahLocator> get items => _items.values;
}

/// Ögenin kayıt bilgisi: [registry]'de [index] ile görünür
mixin RegisteredAyahItem<T extends StatefulWidget> on State<T>
    implements AyahLocator {
  ReaderItemRegistry get registry;
  int get index;

  late ReaderItemRegistry _registeredIn;
  late int _registeredAt;

  @override
  void initState() {
    super.initState();
    _registeredIn = registry..attach(index, this);
    _registeredAt = index;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(registry, _registeredIn) || index != _registeredAt) {
      _registeredIn.detach(_registeredAt, this);
      _registeredIn = registry..attach(index, this);
      _registeredAt = index;
    }
  }

  @override
  void dispose() {
    _registeredIn.detach(_registeredAt, this);
    super.dispose();
  }
}

/// Tek ayetlik öge (ayet kartı): görünen ayet her yerde [ayah]
class SingleAyahItem extends StatefulWidget {
  final ReaderItemRegistry registry;
  final int index;
  final int ayah;
  final Widget child;

  const SingleAyahItem({
    super.key,
    required this.registry,
    required this.index,
    required this.ayah,
    required this.child,
  });

  @override
  State<SingleAyahItem> createState() => _SingleAyahItemState();
}

class _SingleAyahItemState extends State<SingleAyahItem>
    with RegisteredAyahItem<SingleAyahItem> {
  @override
  ReaderItemRegistry get registry => widget.registry;

  @override
  int get index => widget.index;

  @override
  int ayahAt(double dy) => widget.ayah;

  @override
  double offsetOf(int ayah) => 0;

  @override
  Widget build(BuildContext context) => widget.child;
}
