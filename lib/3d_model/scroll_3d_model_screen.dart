// SCROLL-DRIVEN BUILDING + PERSON — Flutter integration
//
// Architecture: a Three.js scene (three_viewer.html) runs inside a WebView.
// Flutter tracks scroll position and calls `setScrollProgress(p)` in JS.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class Scroll3DPage extends StatefulWidget {
  const Scroll3DPage({super.key});
  @override
  State<Scroll3DPage> createState() => _Scroll3DPageState();
}

class _Scroll3DPageState extends State<Scroll3DPage> {
  late final WebViewController _webViewController;
  final ScrollController _scrollController = ScrollController();

  bool _webViewReady = false;
  String? _loadError;

  // How much scroll distance (in logical pixels) maps to the full
  // 0.0 -> 1.0 animation. Tune this to control how "long" the scroll
  // section feels — bigger number = slower/more scroll needed.
  static const double _scrollRangePx = 2400;

  double _lastSentProgress = -1;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _webViewReady = true;
              _loadError = null;
            });
            _sendProgress(0);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loadError = error.description;
            });
          },
        ),
      );

    _scrollController.addListener(_onScroll);
    _loadViewerHtml();
  }

  Future<void> _loadViewerHtml() async {
    try {
      // Prefer loading via the asset bundle + loadHtmlString so iOS WKWebView
      // doesn't depend on loadFlutterAsset path resolution.
      final html = await rootBundle.loadString('assets/three_viewer.html');
      await _webViewController.loadHtmlString(
        html,
        baseUrl: 'https://localhost/',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not load assets/three_viewer.html.\n'
            'Check pubspec.yaml assets, then hot restart.\n\n$e';
      });
    }
  }

  void _onScroll() {
    final double raw = _scrollController.offset / _scrollRangePx;
    final double progress = raw.clamp(0.0, 1.0);
    _sendProgress(progress);
  }

  void _sendProgress(double progress) {
    if (!_webViewReady) return;
    if ((progress - _lastSentProgress).abs() < 0.0015) return;
    _lastSentProgress = progress;
    _webViewController.runJavaScript('setScrollProgress($progress)');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9E2),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _webViewController)),
          if (_loadError != null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xFFEFE9E2),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            )
          else if (!_webViewReady)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _scrollRangePx + MediaQuery.of(context).size.height,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
