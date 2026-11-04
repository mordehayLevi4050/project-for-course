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
      expect(
        MessageKey.activeSheetTitle.text,
        'להפוך את הקבוצה לקבוצה הפעילה?',
      );
      expect(
        MessageKey.activeSheetWarning.fill({'name': 'Eilat'}),
        "הקבוצה 'Eilat' תפסיק להיות הקבוצה הפעילה",
      );
    });

    test('Story 1.2 free texts match EXPERIENCE.md', () {
      expect(
        MessageKey.activeSheetBody.text,
        'האפליקציה תיפתח ישר לתוך הקבוצה הזו.',
      );
      expect(MessageKey.activeSheetConfirm.text, 'כן, להפוך לפעילה');
      expect(MessageKey.activeSheetDecline.text, 'לא עכשיו');
      expect(MessageKey.activeToggle.text, 'קבוצה פעילה');
      expect(MessageKey.activeBadge.text, '⭐ פעילה');
      expect(MessageKey.archivedBadge.text, '🗂 בארכיון');
      expect(MessageKey.archiveLink.fill({'n': '1'}), '🗂 ארכיון (1)');
      expect(MessageKey.archiveAction.text, '🗂 העברה לארכיון');
      expect(
        MessageKey.archiveSheetTitle.fill({'group': 'Budapest'}),
        'להעביר את “Budapest” לארכיון?',
      );
      expect(
        MessageKey.archiveSheetBody.text,
        'הנתונים נשמרים ואפשר לשחזר בכל רגע.',
      );
      expect(MessageKey.archiveSheetConfirm.text, 'העברה לארכיון');
      expect(MessageKey.restore.text, '↩ שחזור');
      expect(MessageKey.restoreFromArchive.text, '↩ שחזור מהארכיון');
      expect(
        MessageKey.archiveNote.text,
        '🗂 הקבוצה בארכיון ולכן לקריאה בלבד. שחזור יחזיר את האפשרות לערוך.',
      );
      expect(
        MessageKey.groupArchived.text,
        '🗂 הקבוצה בארכיון ולכן לקריאה בלבד.',
      );
      expect(MessageKey.archiveNav.text, '→ ארכיון');
      expect(MessageKey.archiveTitle.text, 'ארכיון');
      expect(MessageKey.archiveBackNav.text, '→ הקבוצות שלי');
    });

    test('fill substitutes placeholders', () {
      expect(MessageKey.memberCountMany.fill({'n': '4'}), '4 משתתפים');
      expect(
        MessageKey.removeMemberTitle.fill({'name': isolateName('Dana')}),
        'להסיר את ${iso('Dana')}?',
      );
    });

    test('memberCountText uses the singular for one Member', () {
      expect(memberCountText(1), 'משתתף אחד');
      expect(memberCountText(2), '2 משתתפים');
      expect(memberCountText(0), '0 משתתפים');
    });

    test('Story 1.3 fixed messages match ui-messages.md exactly', () {
      expect(MessageKey.noExpenses.text, 'עדיין אין הוצאות');
      expect(
        MessageKey.needTwoMembers.text,
        'יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות',
      );
      expect(MessageKey.chooseCategory.text, 'נא לבחור קטגוריה');
      expect(
        MessageKey.descriptionRequired.text,
        'נדרש תיאור או בחירת קטגוריה',
      );
      expect(MessageKey.exitTitle.text, 'לצאת ללא שמירה?');
    });

    test('Story 1.3 free texts match EXPERIENCE.md and DESIGN.md', () {
      expect(MessageKey.addExpense.text, '+ הוספת הוצאה');
      expect(MessageKey.descriptionHint.text, 'מה קנית?');
      expect(MessageKey.save.text, 'שמירה');
      expect(MessageKey.exitBody.text, 'מה שהזנת לא יישמר.');
      expect(MessageKey.exitConfirm.text, 'יציאה');
      expect(MessageKey.keepEditing.text, 'המשך עריכה');
      expect(
        [
          MessageKey.categoryFlight,
          MessageKey.categoryHotel,
          MessageKey.categoryCar,
          MessageKey.categoryFuel,
          MessageKey.categoryRestaurant,
          MessageKey.categoryFoodDrink,
          MessageKey.categoryAttractions,
          MessageKey.categoryOther,
        ].map((k) => k.text),
        [
          'טיסה',
          'מלון',
          'רכב',
          'דלק',
          'מסעדה',
          'אוכל ושתייה',
          'אטרקציות',
          'אחר',
        ],
      );
    });

    test('expenseCountText uses the singular for one Expense', () {
      expect(expenseCountText(1), 'הוצאה אחת');
      expect(expenseCountText(2), '2 הוצאות');
      expect(expenseCountText(0), '0 הוצאות');
    });

    test('the Group page header line joins both counts', () {
      expect(
        groupHeaderLineText(memberCount: 4, expenseCount: 8),
        '4 משתתפים · 8 הוצאות',
      );
      expect(
        groupHeaderLineText(memberCount: 1, expenseCount: 1),
        'משתתף אחד · הוצאה אחת',
      );
      expect(
        groupHeaderLineText(memberCount: 2, expenseCount: 0),
        '2 משתתפים · 0 הוצאות',
      );
    });

    test('the Expense meta line isolates the Payer name', () {
      expect(
        MessageKey.expenseMeta.fill({
          'payer': isolateName('Dana'),
          'time': '14:32',
        }),
        '${iso('Dana')} · 14:32',
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
