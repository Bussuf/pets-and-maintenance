import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/widgets/analysis_sections.dart';

/// בדיקות לרוחבי האריחים של 'חלק בחודש' (#91)
/// הרצה: flutter test test/month_part_widths_test.dart
void main() {
  double sum(List<double> l) => l.fold(0, (a, b) => a + b);

  test('3/7, 2/7, 2/7 (rounds to 101%) never exceeds the available width', () {
    // המקרה מהצילום: 43% + 29% + 29% = 101% - היה חורג ב-1% מהשארית
    final widths = monthPartWidths(counts: [3, 2, 2], available: 300, minWidth: 60);
    expect(sum(widths), closeTo(300, 1e-9));
    expect(sum(widths) <= 300 + 1e-9, isTrue);
  });

  test('extra space is split by the exact ratio', () {
    final widths = monthPartWidths(counts: [3, 2, 2], available: 250, minWidth: 40);
    // שארית 130: 3/7, 2/7, 2/7
    expect(widths[0], closeTo(40 + 130 * 3 / 7, 1e-9));
    expect(widths[1], closeTo(40 + 130 * 2 / 7, 1e-9));
    expect(widths[2], closeTo(widths[1], 1e-9));
  });

  test('no completions - equal tiles', () {
    final widths = monthPartWidths(counts: [0, 0, 0], available: 300, minWidth: 60);
    expect(widths, [100, 100, 100]);
  });

  test('not enough room for the minimum - equal tiles that fit', () {
    final widths = monthPartWidths(counts: [5, 1, 0], available: 150, minWidth: 60);
    expect(widths, [50, 50, 50]);
  });

  test('a zero count still gets its minimum width', () {
    final widths = monthPartWidths(counts: [1, 0, 0], available: 300, minWidth: 60);
    expect(widths[1], 60);
    expect(widths[2], 60);
    expect(sum(widths), closeTo(300, 1e-9));
  });
}
