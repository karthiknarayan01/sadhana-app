import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/preferred_script_controller.dart';
import '../domain/reader_pagination.dart';
import '../domain/shloka_result.dart';

/// Full-screen, one-page-at-a-time prayer reader modelled on Apple Books:
/// the prayer is laid out as one continuous styled document and cut into
/// screen-sized pages at line boundaries, so every page is full and nothing
/// scrolls. Swipe horizontally between pages; tap anywhere to reveal a
/// close button and the page position; tap ✕ to leave. The warm gradient
/// and serif / Devanagari type match the rest of the app.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.result});

  final ShlokaResult result;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _chromeVisible = true;
  Timer? _hideTimer;

  static const _hMargin = 26.0;
  static const _topGap = 14.0; // below the safe-area inset
  static const _bottomGap = 30.0; // above the safe-area inset

  _ReaderLayout? _layoutCache;
  String? _layoutCacheKey;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _scheduleHide();
  }

  _ReaderLayout _layoutFor({
    required double areaWidth,
    required double areaHeight,
    required _ReaderStyles styles,
    required TextScaler textScaler,
    required String script,
  }) {
    final key =
        '$script'
        '|${areaWidth.round()}x${areaHeight.round()}'
        '|${textScaler.scale(1000).round()}';
    final cached = _layoutCache;
    if (cached != null && key == _layoutCacheKey) return cached;

    final runs = buildReaderRuns(
      title: widget.result.nameIn(script),
      verse: widget.result.contentIn(script),
      meaning: widget.result.meaningIn(script),
    );
    final text = flattenRuns(runs);

    final painter = TextPainter(
      text: TextSpan(
        children: [
          for (final r in runs)
            TextSpan(text: r.text, style: styles.forKind(r.kind)),
        ],
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: areaWidth);

    final metrics = painter.computeLineMetrics();
    final lineTops = <double>[];
    final lineStarts = <int>[];
    var top = 0.0;
    for (final m in metrics) {
      lineTops.add(top);
      lineStarts.add(
        painter.getPositionForOffset(Offset(0, top + m.height / 2)).offset,
      );
      top += m.height;
    }

    final pages = paginateLines(
      lineTops: lineTops,
      lineStarts: lineStarts,
      totalHeight: painter.height,
      textLength: text.length,
      maxHeight: areaHeight,
    );

    final layout = _ReaderLayout(runs, text, pages);
    _layoutCache = layout;
    _layoutCacheKey = key;
    return layout;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final script = ref.watch(preferredScriptControllerProvider);
    final devanagari = script == 'devanagari';
    final media = MediaQuery.of(context);

    final styles = _ReaderStyles(
      Theme.of(context).textTheme,
      scheme,
      devanagari: devanagari,
    );

    final topInset = media.padding.top + _topGap;
    final bottomInset = media.padding.bottom + _bottomGap;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final areaWidth = constraints.maxWidth - _hMargin * 2;
            final areaHeight = constraints.maxHeight - topInset - bottomInset;

            final layout = _layoutFor(
              areaWidth: areaWidth,
              areaHeight: areaHeight,
              styles: styles,
              textScaler: media.textScaler,
              script: script,
            );
            final pages = layout.pages;

            if (_page > pages.length - 1) {
              _page = pages.length - 1;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _controller.hasClients) {
                  _controller.jumpToPage(_page);
                }
              });
            }

            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleChrome,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) {
                      setState(() => _page = i);
                      if (_chromeVisible) _scheduleHide();
                    },
                    itemBuilder: (context, i) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        _hMargin,
                        topInset,
                        _hMargin,
                        bottomInset,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _PageText(
                          runs: layout.runs,
                          text: layout.text,
                          slice: pages[i],
                          styles: styles,
                        ),
                      ),
                    ),
                  ),
                ),
                _ReaderChrome(
                  visible: _chromeVisible,
                  page: _page,
                  count: pages.length,
                  scheme: scheme,
                  topInset: media.padding.top,
                  bottomInset: media.padding.bottom,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReaderLayout {
  const _ReaderLayout(this.runs, this.text, this.pages);

  final List<ReaderRun> runs;
  final String text;
  final List<PageSlice> pages;
}

/// Renders one page: each run clipped to the page's character range, with
/// any blank lines the cut left at the very top trimmed away.
class _PageText extends StatelessWidget {
  const _PageText({
    required this.runs,
    required this.text,
    required this.slice,
    required this.styles,
  });

  final List<ReaderRun> runs;
  final String text;
  final PageSlice slice;
  final _ReaderStyles styles;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var trimmedLead = false;
    for (final part in runSlicesFor(runs, text, slice)) {
      var t = part.text;
      if (!trimmedLead) {
        t = t.replaceFirst(RegExp(r'^\s+'), '');
        if (t.isEmpty) continue;
        trimmedLead = true;
      }
      spans.add(TextSpan(text: t, style: styles.forKind(part.kind)));
    }
    return Text.rich(TextSpan(children: spans));
  }
}

/// The text roles the reader renders, resolved once per build so
/// measurement and painting stay in lockstep.
class _ReaderStyles {
  _ReaderStyles(TextTheme text, ColorScheme scheme, {required bool devanagari})
    : title = (text.headlineMedium ?? const TextStyle(fontSize: 28)).copyWith(
        fontFamily: devanagari ? 'NotoSansDevanagari' : 'Merriweather',
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: scheme.onSurface,
      ),
      _gap = const TextStyle(fontSize: 15, height: 1.2),
      verse = devanagari
          ? TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 22,
              height: 1.9,
              color: scheme.onSurface,
            )
          : TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 18,
              height: 1.75,
              fontStyle: FontStyle.italic,
              color: scheme.onSurface,
            ),
      meaningHeading = (text.labelLarge ?? const TextStyle(fontSize: 14))
          .copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
      meaning = TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 16,
        height: 1.7,
        color: scheme.onSurface,
      );

  final TextStyle title;
  final TextStyle _gap;
  final TextStyle verse;
  final TextStyle meaningHeading;
  final TextStyle meaning;

  TextStyle forKind(ReaderRunKind kind) => switch (kind) {
    ReaderRunKind.title => title,
    ReaderRunKind.gap => _gap,
    ReaderRunKind.verse => verse,
    ReaderRunKind.meaningHeading => meaningHeading,
    ReaderRunKind.meaning => meaning,
  };
}

class _ReaderChrome extends StatelessWidget {
  const _ReaderChrome({
    required this.visible,
    required this.page,
    required this.count,
    required this.scheme,
    required this.topInset,
    required this.bottomInset,
    required this.onClose,
  });

  final bool visible;
  final int page;
  final int count;
  final ColorScheme scheme;
  final double topInset;
  final double bottomInset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: [
            Positioned(
              top: topInset + 4,
              left: 8,
              child: IconButton.filledTonal(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 10,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: 132,
                        height: 3,
                        child: LinearProgressIndicator(
                          value: count <= 1 ? 1 : (page + 1) / count,
                          backgroundColor: scheme.onSurface.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: AlwaysStoppedAnimation(scheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${page + 1} of $count',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
