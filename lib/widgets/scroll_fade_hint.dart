import 'package:flutter/material.dart';

/// רמז גלילה (#58): כשיש עוד תוכן מתחת, התחתית של אזור הגלילה "נמסה" לרקע.
/// כשמגיעים לסוף (או כשהכל נכנס במסך) - ההצללה נעלמת.
class ScrollFadeHint extends StatefulWidget {
  final Widget child;
  final double fadeHeight;

  const ScrollFadeHint({super.key, required this.child, this.fadeHeight = 40});

  @override
  State<ScrollFadeHint> createState() => _ScrollFadeHintState();
}

class _ScrollFadeHintState extends State<ScrollFadeHint> {
  bool _hasMore = false;

  bool _update(ScrollMetrics metrics, int depth) {
    // רק הגלילה הראשית (לא גלילות פנימיות, כמו שורת הצ'יפים האופקית)
    if (depth != 0 || metrics.axis != Axis.vertical) return false;
    final hasMore = metrics.extentAfter > 1;
    if (hasMore != _hasMore) setState(() => _hasMore = hasMore);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _update(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _update(n.metrics, n.depth),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final start = bounds.height <= widget.fadeHeight
                ? 0.0
                : (bounds.height - widget.fadeHeight) / bounds.height;
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white,
                _hasMore ? Colors.transparent : Colors.white,
              ],
              stops: [0.0, start, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
