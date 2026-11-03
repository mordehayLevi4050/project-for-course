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

  // --- Group list --------------------------------------------------------
  appName('GrouPay'),
  myGroups('הקבוצות שלי'),
  newGroup('+ קבוצה חדשה'),

  // --- Group page header ---------------------------------------------------
  /// The header nav back to the group list.
  groupListNav('☰ הקבוצות שלי'),

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
  addMember('+ הוספת משתתף'),
  renameTitle('שינוי שם'),
  save('שמירה'),
  cancel('ביטול'),

  /// {name} must be the result of `isolateName()`.
  removeMemberTitle('להסיר את {name}?'),
  removeMemberBody('ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים.'),
  removeMemberConfirm('הסרה'),

  // --- Exit sheet --------------------------------------------------------
  exitTitle('לצאת ללא שמירה?'),
  exitBody('מה שהזנת לא יישמר.'),
  exitConfirm('יציאה'),
  keepEditing('המשך עריכה'),

  // --- Counts ------------------------------------------------------------
  memberCountOne('משתתף אחד'),
  memberCountMany('{n} משתתפים');

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
