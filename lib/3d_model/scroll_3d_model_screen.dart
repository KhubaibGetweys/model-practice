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
  static const double _scrollRangePx = 2400;

  static const double _endThreshold = 0.98;

  double _lastSentProgress = -1;
  double _progress = 0;
  bool _showEndUi = false;

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

    final atEnd = progress >= _endThreshold;
    if (atEnd != _showEndUi || (progress - _progress).abs() > 0.01) {
      setState(() {
        _progress = progress;
        _showEndUi = atEnd;
      });
    }
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
              // 3D scroll range
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _scrollRangePx + MediaQuery.of(context).size.height,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 320)),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showEndUi,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                offset: _showEndUi ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 320),
                  opacity: _showEndUi ? 1 : 0,
                  child: const _EndFlutterPanel(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndFlutterPanel extends StatelessWidget {
  const _EndFlutterPanel();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You reached the ground floor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is Flutter UI shown when the 3D scroll ends. '
              'Replace this panel with your real content.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End CTA tapped')),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
