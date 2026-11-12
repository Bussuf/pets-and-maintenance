import 'package:flutter_test/flutter_test.dart';
import 'package:pets_and_maintenance/widgets/analysis_sections.dart';

/// בדיקות למובילים ב"זמני ביצוע" (#59): תיקו בלי מוביל שרירותי
/// הרצה: flutter test test/when_leaders_test.dart
void main() {
  // סדר תצוגה כמו בעברית: ראשון (7) קודם
  const order = [7, 1, 2, 3, 4, 5, 6];

  test('a single leader', () {
    expect(leadersOf(order, {7: 1, 1: 0, 2: 4, 3: 1, 4: 0, 5: 0, 6: 0}), [2]);
  });

  test('a two-way tie keeps both, in display order', () {
    expect(leadersOf(order, {7: 0, 1: 0, 2: 3, 3: 0, 4: 3, 5: 1, 6: 0}), [2, 4]);
  });

  test('a three-way tie keeps all three', () {
    expect(leadersOf(const [0, 1, 2], {0: 2, 1: 2, 2: 2}), [0, 1, 2]);
  });

  test('no completions - no leaders', () {
    expect(leadersOf(const [0, 1, 2], {0: 0, 1: 0, 2: 0}), isEmpty);
  });
}
