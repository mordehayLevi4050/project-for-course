import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/isolate_name.dart';
import 'package:groupay/core/i18n/message_key.dart';

String iso(String s) => '\u2068$s\u2069';

void main() {
  group('isolateName', () {
    test('"Dana" after "מ" gets a hyphen and FSI/PDI', () {
      expect(isolateName('Dana', prefix: 'מ'), 'מ-${iso('Dana')}');
    });

    test('a Hebrew name after a prefix has no hyphen', () {
      expect(isolateName('דנה', prefix: 'ל'), 'ל${iso('דנה')}');
    });

    test('digits, emoji and mixed names start without a Hebrew letter', () {
      expect(isolateName('7up', prefix: 'מ'), 'מ-${iso('7up')}');
      expect(isolateName('😀', prefix: 'ל'), 'ל-${iso('😀')}');
      expect(isolateName('Zoe כהן', prefix: 'ל'), 'ל-${iso('Zoe כהן')}');
      expect(isolateName('דן Lee', prefix: 'מ'), 'מ${iso('דן Lee')}');
    });

    test('without a prefix the name is only isolated', () {
      expect(isolateName('Dana'), iso('Dana'));
      expect(isolateName('דנה'), iso('דנה'));
    });
  });

  group('MessageKey', () {
    test('fixed messages match ui-messages.md exactly', () {
      expect(MessageKey.nameRequired.text, 'נדרש שם');
      expect(MessageKey.groupNameTaken.text, 'כבר קיימת קבוצה בשם הזה');
      expect(MessageKey.memberNameTaken.text, 'כבר יש משתתף בשם הזה');
      expect(MessageKey.membersLimit.text, 'קבוצות מוגבלות ל-10 משתתפים');
      expect(
        MessageKey.memberIsPayer.text,
        'לא ניתן להסיר משתתף שיש הוצאה על שמו',
      );
      expect(MessageKey.emptyGroupList.text, 'כאן תופיע רשימת הקבוצות');
      expect(MessageKey.invalidAmount.text, 'סכום לא תקין');
      expect(MessageKey.newGroup.text, '+ קבוצה חדשה');
    });

    test('fill substitutes placeholders', () {
      expect(MessageKey.memberCountMany.fill({'n': '4'}), '4 משתתפים');
      expect(
        MessageKey.removeMemberTitle.fill({'name': isolateName('Dana')}),
        'להסיר את ${iso('Dana')}?',
      );
    });

    test('fill does not expand braces inside a value', () {
      expect(MessageKey.memberCountMany.fill({'n': '{n}'}), '{n} משתתפים');
    });

    test('fill rejects a missing or an unknown placeholder', () {
      expect(() => MessageKey.memberCountMany.fill({}), throwsArgumentError);
      expect(
        () => MessageKey.memberCountMany.fill({'n': '1', 'x': '2'}),
        throwsArgumentError,
      );
    });

    test('every message has text, and placeholders are well formed', () {
      for (final key in MessageKey.values) {
        expect(key.text.trim(), isNotEmpty, reason: key.name);
        expect(key.text, isNot(contains('{}')), reason: key.name);
      }
    });
  });
}
