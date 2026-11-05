import '../money/format_shekel.dart';
import '../money/tenths.dart';
import 'isolate_name.dart';

/// Every user-visible string in the app (AD-14). Widgets hold no Hebrew
/// literals; they show `MessageKey.x.text` or `MessageKey.x.fill({...})`.
///
/// The fixed messages (marked "fixed") are copied verbatim from
/// `specs/spec-groupay/ui-messages.md` and must never be reworded. The rest is
/// the free UI copy from EXPERIENCE.md › Voice and Tone.
///
/// User-entered names enter a sentence only through `isolateName()`.
enum MessageKey {
  // --- Fixed messages (ui-messages.md) ---------------------------------
  /// fixed: "Name required"
  nameRequired('נדרש שם'),

  /// fixed: "Group already exists"
  groupNameTaken('כבר קיימת קבוצה בשם הזה'),

  /// fixed: "Member already exists"
  memberNameTaken('כבר יש משתתף בשם הזה'),

  /// fixed: "A group can have at most 10 members"
  membersLimit('קבוצות מוגבלות ל-10 משתתפים'),

  /// fixed: "A member with expenses in their name cannot be removed"
  memberIsPayer('לא ניתן להסיר משתתף שיש הוצאה על שמו'),

  /// fixed: "The list of groups will appear here"
  emptyGroupList('כאן תופיע רשימת הקבוצות'),

  /// fixed: "Please enter a valid amount"
  invalidAmount('סכום לא תקין'),

  /// fixed: the Active-group sheet title (FR-7).
  activeSheetTitle('להפוך את הקבוצה לקבוצה הפעילה?'),

  /// fixed: another Group is active (FR-7). {name} must be the result of
  /// `isolateName()`.
  activeSheetWarning("הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה"),

  /// fixed: "No expenses yet" (FR-12).
  noExpenses('עדיין אין הוצאות'),

  /// fixed: "Add at least two members to record expenses" (FR-10).
  needTwoMembers('יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות'),

  /// fixed: "Please choose a category" (FR-11).
  chooseCategory('נא לבחור קטגוריה'),

  /// fixed: "Description required, or choose a category" (FR-11).
  descriptionRequired('נדרש תיאור או בחירת קטגוריה'),

  // --- Internal failures (repository guards; the UI never offers these) ---
  /// A write on an Archived group (FR-6): the short archive note.
  groupArchived('🗂 הקבוצה בארכיון ולכן לקריאה בלבד.'),

  /// Restoring a Group that is not archived.
  groupNotArchived('הקבוצה לא בארכיון'),

  // --- Group list --------------------------------------------------------
  appName('GrouPay'),
  myGroups('הקבוצות שלי'),
  newGroup('+ קבוצה חדשה'),

  /// The link under the last Group card; hidden when {n} is 0.
  archiveLink('🗂 ארכיון ({n})'),

  /// The badge of the Active group's card.
  activeBadge('⭐ פעילה'),

  // --- Active-group sheet (FR-7, FR-8) -----------------------------------
  activeSheetBody('האפליקציה תיפתח ישר לתוך הקבוצה הזו.'),
  activeSheetConfirm('כן, להפוך לפעילה'),
  activeSheetDecline('לא עכשיו'),

  // --- Archive (FR-6) ------------------------------------------------------
  /// The Archive view title.
  archiveTitle('ארכיון'),

  /// The Archive view nav back to the group list (drawn after the chevron
  /// icon by `NavBackLabel`).
  archiveBackNav('הקבוצות שלי'),

  /// The header nav of an archived Group page, back to the Archive view
  /// (drawn after the chevron icon by `NavBackLabel`).
  archiveNav('ארכיון'),

  /// The header badge of an archived Group.
  archivedBadge('🗂 בארכיון'),

  /// The text button on an archived card.
  restore('↩ שחזור'),

  /// The primary button of an archived Group page.
  restoreFromArchive('↩ שחזור מהארכיון'),

  /// The strip above the bottom bar of an archived Group page.
  archiveNote(
    '🗂 הקבוצה בארכיון ולכן לקריאה בלבד. שחזור יחזיר את האפשרות לערוך.',
  ),

  /// The note under the Transfer cards of an archived Summary
  /// (EXPERIENCE.md › Archived Summary).
  archiveSummaryNote('🗂 הקבוצה בארכיון ולכן לקריאה בלבד.'),

  /// The Group settings row that opens the Archive sheet.
  archiveAction('🗂 העברה לארכיון'),

  /// {group} must be the result of `isolateName()`.
  archiveSheetTitle('להעביר את “{group}” לארכיון?'),
  archiveSheetBody('הנתונים נשמרים ואפשר לשחזר בכל רגע.'),
  archiveSheetConfirm('העברה לארכיון'),

  // --- Group page header ---------------------------------------------------
  /// The header nav back to the group list (drawn after the chevron icon by
  /// `NavBackLabel`).
  groupListNav('הקבוצות שלי'),

  /// The tap-affordance chip next to the group name (opens Group settings).
  groupSettingsChip('⚙ ✎'),

  // --- Create group ------------------------------------------------------
  newGroupTitle('קבוצה חדשה'),
  groupNameLabel('שם הקבוצה'),
  createGroup('יצירת קבוצה'),
  membersSection('משתתפים'),
  memberNamePlaceholder('שם המשתתף'),
  done('סיום'),

  /// The add-member button inside the field.
  addMemberButton('+'),

  /// The compact top bar close control.
  close('✕'),

  // --- Group settings and sheets -----------------------------------------
  groupSettingsTitle('הגדרות קבוצה'),

  /// The Active toggle row in Group settings (FR-8).
  activeToggle('קבוצה פעילה'),
  addMember('+ הוספת משתתף'),
  renameTitle('שינוי שם'),
  save('שמירה'),
  cancel('ביטול'),

  /// {name} must be the result of `isolateName()`.
  removeMemberTitle('להסיר את {name}?'),

  /// The Remove-member body when the Group has Expenses; {n} is the number of
  /// Members left (2 or more).
  removeMemberBody('ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים.'),

  /// The Remove-member body when the Group has Expenses and one Member is
  /// left.
  removeMemberBodyOne('כל ההוצאות יחולו על המשתתף הנותר.'),
  removeMemberConfirm('הסרה'),

  /// The semantics label of the compact top bar back control, which shows
  /// the chevron icon alone (start side, RTL).
  back('חזרה'),

  /// The Members section label in Group settings.
  membersCount('משתתפים ({n})'),

  /// A settings-row value that opens more. {value} is a name, so it must be
  /// the result of `isolateName()`.
  rowValue('{value} ›'),

  /// The rename control on a Member row.
  renameGlyph('✎'),

  /// The remove control on a Member row.
  removeGlyph('✕'),

  // --- Exit sheet --------------------------------------------------------
  exitTitle('לצאת ללא שמירה?'),
  exitBody('מה שהזנת לא יישמר.'),
  exitConfirm('יציאה'),
  keepEditing('המשך עריכה'),

  // --- Group page and Add expense (FR-10–FR-12) --------------------------
  /// The primary button of the Group page.
  addExpense('+ הוספת הוצאה'),

  /// The Description field placeholder (*Other*).
  descriptionHint('מה קנית?'),

  /// The header secondary line: {members} and {expenses} are the count texts.
  groupHeaderLine('{members} · {expenses}'),

  /// An Expense row's meta line. {payer} must be the result of
  /// `isolateName()`; {time} comes from `formatExpenseTime()`.
  expenseMeta('{payer} · {time}'),

  /// The currency mark before the typed Amount.
  currencyMark('₪'),

  /// The keypad's delete key.
  keypadBackspace('⌫'),

  // --- Edit and delete an Expense (FR-13, FR-14) ---------------------------
  /// The danger chip on the end side of the Edit expense top bar.
  deleteChip('🗑 מחיקה'),

  /// fixed: the Delete sheet title (FR-14).
  deleteTitle('למחוק את ההוצאה?'),
  deleteBody('אי אפשר לבטל את הפעולה.'),
  deleteConfirm('מחיקה'),

  /// The expense line of the Delete sheet. {payer} must be the result of
  /// `isolateName()`; {amount} comes from `formatShekel()` (it carries ₪).
  expenseLine('{emoji} {title} · {payer} · {amount}'),

  /// The snackbar after a delete.
  expenseDeleted('ההוצאה נמחקה'),

  /// The Edit expense meta line; {time} comes from `formatExpenseTime()`.
  recordedMeta('נרשם {time}'),

  /// Appended to [recordedMeta] once the Expense was saved with a change.
  editedMeta(' · נערך {time}'),

  // --- Categories (fixed order; DESIGN.md › Category tile) ---------------
  categoryFlight('טיסה'),
  categoryHotel('מלון'),
  categoryCar('רכב'),
  categoryFuel('דלק'),
  categoryRestaurant('מסעדה'),
  categoryFoodDrink('אוכל ושתייה'),
  categoryAttractions('אטרקציות'),
  categoryOther('אחר'),

  // --- Summary (FR-15, FR-16) ---------------------------------------------
  /// The Summary header nav back to the Group page (drawn after the chevron
  /// icon by `NavBackLabel`).
  summaryNav('חזרה'),

  /// The secondary button of the Group page bottom bar.
  summaryButton('סיכום'),

  /// The Summary section title above the Transfer cards.
  transfersTitle('מי מעביר למי'),

  /// The Summary header line; {members} comes from `memberCountText()` and
  /// {share} from `formatShekel()` (it carries ₪).
  shareLine('{members} · {share} לאחד'),

  /// fixed: "Everyone is settled up" (FR-16).
  settledUp('החשבון מאוזן, אין צורך בהעברות'),

  /// fixed: "Payment due from {debtor} to {receiver} ₪N" (FR-16), without
  /// the amount, which closes the line as its own widget. {from} and {to}
  /// must be `isolateName()` with the prefixes "מ" and "ל".
  transferLine('תשלום נדרש {from} {to}'),

  // --- Counts ------------------------------------------------------------
  memberCountOne('משתתף אחד'),
  memberCountMany('{n} משתתפים'),
  expenseCountOne('הוצאה אחת'),
  expenseCountMany('{n} הוצאות');

  const MessageKey(this.text);

  /// The Hebrew text shown in the app.
  final String text;

  /// The text with each `{placeholder}` replaced by its value in [args].
  ///
  /// Throws an [ArgumentError] when a placeholder has no value or a value has
  /// no placeholder, so a typo fails a test instead of reaching the screen.
  String fill(Map<String, String> args) {
    final missing = _placeholder
        .allMatches(text)
        .map((m) => m.group(1)!)
        .where((p) => !args.containsKey(p))
        .toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('$name needs a value for $missing');
    }
    final extra = args.keys.where((k) => !text.contains('{$k}')).toList();
    if (extra.isNotEmpty) {
      throw ArgumentError('$name has no placeholder for $extra');
    }
    // One pass, so a value that happens to contain "{x}" is never expanded.
    return text.replaceAllMapped(_placeholder, (m) => args[m.group(1)!]!);
  }

  static final RegExp _placeholder = RegExp(r'\{(\w+)\}');
}

/// "משתתף אחד" for one Member, otherwise "{n} משתתפים".
String memberCountText(int count) => count == 1
    ? MessageKey.memberCountOne.text
    : MessageKey.memberCountMany.fill({'n': '$count'});

/// "הוצאה אחת" for one Expense, otherwise "{n} הוצאות" (also for 0).
String expenseCountText(int count) => count == 1
    ? MessageKey.expenseCountOne.text
    : MessageKey.expenseCountMany.fill({'n': '$count'});

/// The Summary header line "{n} משתתפים · ₪{share} לאחד".
String shareLineText({required int memberCount, required Tenths share}) =>
    MessageKey.shareLine.fill({
      'members': memberCountText(memberCount),
      'share': formatShekel(share),
    });

/// A Transfer card's sentence "תשלום נדרש מ{debtor} ל{receiver}" (the
/// amount is shown after it, through `formatShekel()`).
String transferLineText({required String debtor, required String receiver}) =>
    MessageKey.transferLine.fill({
      'from': isolateName(debtor, prefix: 'מ'),
      'to': isolateName(receiver, prefix: 'ל'),
    });

/// The Group page header line "{n} משתתפים · {m} הוצאות".
String groupHeaderLineText({
  required int memberCount,
  required int expenseCount,
}) => MessageKey.groupHeaderLine.fill({
  'members': memberCountText(memberCount),
  'expenses': expenseCountText(expenseCount),
});
