import 'package:flutter/material.dart';

import '../../features/common/widgets/ad_banner_widget.dart';

/// İç ekranların ortak iskeleti: tek AppBar stili + altta banner reklam.
///
/// [padding] verilirse gövde bu boşlukla sarılır (liste ekranlarında genelde
/// boş bırakılıp listeye padding verilir).
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final bool showBanner;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry? padding;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
    this.showBanner = true,
    this.automaticallyImplyLeading = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
        bottom: bottom,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: padding == null ? body : Padding(padding: padding!, child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBanner
          ? const SafeArea(top: false, child: AdBannerWidget())
          : null,
    );
  }
}
