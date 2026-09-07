// SCROLL-DRIVEN BUILDING + PERSON — Flutter integration
//
// Architecture: a Three.js scene (three_viewer.html, generated separately)
// runs inside a WebView. The GLB models are embedded as base64 inside
// that HTML file, so there's no separate asset-loading step for them.
// Flutter's job is just: track scroll position -> call
// `setScrollProgress(p)` inside the WebView on every scroll frame.
//
// SETUP
// 1. flutter pub add webview_flutter
// 2. Put three_viewer.html in assets/ and register it in pubspec.yaml:
//      flutter:
//        assets:
//          - assets/three_viewer.html
// 3. This harness loads Three.js from a CDN (jsdelivr) at runtime, so the
//    device needs internet access the first time (browser-cached after).
//    If you need fully offline operation, download the three.module.js +
//    GLTFLoader.js files, bundle them under assets/, and change the
//    <script type="importmap"> URLs in three_viewer.html to local paths.
// 4. Replace your page body with Scroll3DPage below.

import 'package:flutter/material.dart';
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
      ..setBackgroundColor(const Color(0x00000000)) // transparent
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _webViewReady = true);
            _sendProgress(0); // initialize scene at scrollProgress = 0
          },
        ),
      )
      ..loadFlutterAsset('assets/three_viewer.html');

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final double raw = _scrollController.offset / _scrollRangePx;
    final double progress = raw.clamp(0.0, 1.0);
    _sendProgress(progress);
  }

  void _sendProgress(double progress) {
    if (!_webViewReady) return;
    // Cheap de-dupe so we don't spam the JS bridge on tiny scroll deltas.
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
          // The 3D scene stays pinned full-screen; the WebView itself
          // never scrolls — only setScrollProgress() changes what's shown.
          Positioned.fill(child: WebViewWidget(controller: _webViewController)),
          if (!_webViewReady)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),

          // Invisible scroll surface on top — its offset is the only thing
          // driving the 3D scene. Swap the SizedBox height / sections for
          // your real page content (text sections, CTAs, etc. can sit in
          // here too, laid out however you like around the pinned 3D view).
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
