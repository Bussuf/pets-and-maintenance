import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../providers/locale_provider.dart';

// עוטף את קריאות הרשת ומוסיף להן את טוקן האימות של גוגל
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleCalendarService {
  static final GoogleCalendarService instance = GoogleCalendarService._();
  GoogleCalendarService._();

  // מבקש הרשאה לנהל אירועים ביומן
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [cal.CalendarApi.calendarEventsScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  // הפונקציה החדשה להוספה: בודקת אם כבר התחברנו בעבר וחוסכת למשתמש לחיצה
  Future<GoogleSignInAccount?> signInSilently() async {
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  bool get isSignedIn => _currentUser != null;

  Future<cal.CalendarApi?> _getCalendarApi() async {
    if (_currentUser == null) return null;
    final headers = await _currentUser!.authHeaders;
    final client = GoogleAuthClient(headers);
    return cal.CalendarApi(client);
  }

  // יצירת אירוע יום שלם (All-Day Event)
  Future<String?> createEvent(AppTask task, String itemAndCategoryDetails) async {
    if (task.nextDueDate == null) return null;

    final api = await _getCalendarApi();
    if (api == null) return null;

    final event = cal.Event()
      ..summary = LocaleNotifier.l10n.calendarEventTitle(task.name)
      ..description = '${task.description ?? ''}\n\n$itemAndCategoryDetails\n\n${LocaleNotifier.l10n.calendarAutoCreated}';

    // הגדרת אירוע ליום שלם (מתחיל בתאריך ומסתיים ביום למחרת)
    final startDate = DateTime(task.nextDueDate!.year, task.nextDueDate!.month, task.nextDueDate!.day);
    final endDate = startDate.add(const Duration(days: 1));

    event.start = cal.EventDateTime()..date = startDate;
    event.end = cal.EventDateTime()..date = endDate;

    try {
      // primary = היומן הראשי של המשתמש
      final createdEvent = await api.events.insert(event, 'primary');
      return createdEvent.id;
    } catch (e) {
      debugPrint('Google Calendar create failed: $e');
      return null;
    }
  }

  // עדכון תאריך או פרטי אירוע קיים
  // מחזיר false אם העדכון נכשל (למשל בלי אינטרנט)
  Future<bool> updateEvent(AppTask task, String itemAndCategoryDetails) async {
    if (task.googleEventId == null || task.nextDueDate == null) return true; // אין מה לעדכן

    final api = await _getCalendarApi();
    if (api == null) return false;

    final event = cal.Event()
      ..summary = LocaleNotifier.l10n.calendarEventTitle(task.name)
      ..description = '${task.description ?? ''}\n\n$itemAndCategoryDetails\n\n${LocaleNotifier.l10n.calendarAutoCreated}';

    final startDate = DateTime(task.nextDueDate!.year, task.nextDueDate!.month, task.nextDueDate!.day);
    final endDate = startDate.add(const Duration(days: 1));

    event.start = cal.EventDateTime()..date = startDate;
    event.end = cal.EventDateTime()..date = endDate;

    try {
      await api.events.update(event, 'primary', task.googleEventId!);
      return true;
    } catch (e) {
      debugPrint('Google Calendar update failed: $e');
      return false;
    }
  }

  // מחיקת אירוע (מופעל כאשר המשימה נמחקת או כשהמתג מכובה)
  // מחזיר false אם המחיקה נכשלה (למשל בלי אינטרנט)
  Future<bool> deleteEvent(String eventId) async {
    final api = await _getCalendarApi();
    if (api == null) return false;

    try {
      await api.events.delete('primary', eventId);
      return true;
    } catch (e) {
      debugPrint('Google Calendar delete failed: $e');
      return false;
    }
  }
}