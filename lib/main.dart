import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const TimerNeoApp());

class TimerNeoApp extends StatelessWidget {
  const TimerNeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF070707),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFEFEFEF),
              displayColor: const Color(0xFFEFEFEF),
            ),
      ),
      home: const TimerHome(),
    );
  }
}

class TimerHome extends StatefulWidget {
  const TimerHome({super.key});

  @override
  State<TimerHome> createState() => _TimerHomeState();
}

class _TimerHomeState extends State<TimerHome> with TickerProviderStateMixin {
  // Timer
  final Stopwatch _sw = Stopwatch();
  Timer? _tick;
  bool _running = false;

  // Anim
  late final AnimationController _slideCtrl;
  late final CurvedAnimation _slideCurve;
  late final Animation<Offset> _timerSlide;
  late final Animation<double> _timerFade;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560), // smoother, slightly longer
    );

    // Smoother curve (less “snappy” than easeOutCubic)
    _slideCurve = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCubicEmphasized,
    );

    _timerSlide = Tween<Offset>(
      begin: const Offset(0, 0.26),
      end: Offset.zero,
    ).animate(_slideCurve);

    _timerFade = Tween<double>(begin: 0, end: 1).animate(_slideCurve);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _startTicking() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      if (!_running) return;
      setState(() {});
    });
  }

  void _stopTicking() {
    _tick?.cancel();
    _tick = null;
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _sw
        ..reset()
        ..start();
    });
    _startTicking();
    _slideCtrl.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _stop() {
    if (!_running) return;
    _sw.stop();
    setState(() => _running = false);
    _stopTicking();
    _slideCtrl.reverse();
    HapticFeedback.selectionClick();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _format(Duration d) {
    final ms = d.inMilliseconds;
    final totalSeconds = ms ~/ 1000;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final hundredths = (ms ~/ 10) % 100;
    return "${_two(h)}:${_two(m)}:${_two(s)}.${_two(hundredths)}";
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _format(_sw.elapsed);

    const green = Color(0xFF00FF66);
    const red = Color(0xFFFF2D2D);

    return Scaffold(
      body: Stack(
        children: [
          const _MonoGridBackground(),

          // Top bar pills
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  _IconPill(
                    icon: Icons.menu_rounded,
                    onTap: () {},
                    tooltip: "Menu",
                  ),
                  const Spacer(),
                  _IconPill(
                    icon: Icons.search_rounded,
                    onTap: () {},
                    tooltip: "Search",
                  ),
                ],
              ),
            ),
          ),

          // Main
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TIMER (numbers only, smoother slide)
                    IgnorePointer(
                      ignoring: !_running,
                      child: AnimatedBuilder(
                        animation: _slideCtrl,
                        builder: (_, __) {
                          final hf = lerpDouble(0.0, 1.0, _slideCtrl.value)!.clamp(0.0, 1.0);

                          return ClipRect(
                            child: Align(
                              alignment: Alignment.center,
                              heightFactor: hf,
                              child: FadeTransition(
                                opacity: _timerFade,
                                child: SlideTransition(
                                  position: _timerSlide,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      timeText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.9,
                                        color: Color(0xFFF2F2F2),
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Button holder card
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0E0E).withOpacity(0.80),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 34,
                            spreadRadius: 1,
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ],
                      ),
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOutCubicEmphasized,
                        tween: ColorTween(
                          begin: green,
                          end: _running ? red : green,
                        ),
                        builder: (context, btnColor, _) {
                          final c = btnColor ?? green;

                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeInOutCubicEmphasized,
                            tween: Tween<double>(
                              begin: 0,
                              end: _running ? 1.0 : 0.0,
                            ),
                            builder: (context, t, __) {
                              // subtle “alive” feel during transition
                              final scale = 1.0 - (0.02 * (t - 0.5).abs() * 2);
                              return Transform.scale(
                                scale: scale,
                                child: SizedBox(
                                  width: 290,
                                  height: 66,
                                  child: ElevatedButton(
                                    onPressed: _running ? _stop : _start,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: c,
                                      foregroundColor: _running ? Colors.white : Colors.black,
                                      elevation: 14,
                                      shadowColor: c.withOpacity(0.38),
                                      // IMPORTANT: no border/outline
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, anim) => FadeTransition(
                                        opacity: anim,
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
                                          child: child,
                                        ),
                                      ),
                                      child: Text(
                                        _running ? "STOP" : "START",
                                        key: ValueKey(_running),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Background: black/white grid
// =========================================================
class _MonoGridBackground extends StatelessWidget {
  const _MonoGridBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF070707)),
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.1,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF070707);
    canvas.drawRect(Offset.zero & size, bg);

    final spacing = 42.0;
    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.045)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final dotPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.06);
    const dotR = 1.2;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================
// Top pill buttons
// =========================================================
class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E).withOpacity(0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.90)),
          ),
        ),
      ),
    );
  }
}
