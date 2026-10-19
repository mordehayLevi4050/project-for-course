# exercise 2 : A six-layer development prompt

## מטרת הפרומט

: הוספת יכולת חישוב כל הוצאה בקבוצה רק לחלק מהמשתתפים בקבוצה ולא כל הוצאה בשווה לכולם

## prompt:

you are a senior Flutter developer
in file settlement.dart the factory Settlement.of calculate the total amount of the group equally among all participants. and in add_expense_screen.dart the children of groupayappbar contains 4 fields for the amount , who paid , of what paid, and expanse detailes. this assumes that every expense is shared equally amonge everyone. it need to change to know each expanse with where to shared and calculate the division according to this.
your task is to add in add_expense_screen.dart the field עם מי מתחלק? and allow the user to choose whether everyone participates in the expanse or select specific participants. Afterwards in settlement.dart file in the factory Settlement.of you need change the calculate instead total/members to calculate each expanse per its participants and display the result who owes whon in the group_screen.dart file according this calculation. and also in models/expense.dart you need to add a field with an array of the participants id's.  
you modified only the settlement.dart , add_expense_screen.dart and expense.dart. you only focus on the allow the unequally distributing. you dont change the style excluding to add the למי מתחלק field dont fix other bugs that are not related to this calculation. your task is done when the user can split an expense with specific members and the result in the group_screen.dart display the unequally distributing. 
return the list of the files you modified.
calculation for example: the Budapest trip group contain Motty, Dany, Yosi, and Shmulik. Motty paid 200 shekels shared with all members and Dany also paid  200 shekels shared with everyone., now Yosi owes to Motty 100 and Shmulik owes to Dany 100. now Yosi add an expense of 100 Shekel but shared it only with Shmulik. the calculation result need to be Yosi owes Motty 100 and Shmulik owes Dany 100 and also 50 for yosi

# exercise 3 : A prompt structured with tags

## מטרת הפרומט

: הפיכת השדה "על מה" בהוספת הוצאה מטקסט חופשי לבחירה מרשימת קטגוריות שנשמרת בקובץ הנתונים, ופירוט חובה כשנבחרת הקטגוריה "אחר"

## prompt:

```
<role> you are a senior Flutter developer </role>
<context>
In add_expense_screen.dart one of the fields in the adding an expense is the field על מה what was the expense for. now it is a free text I want to force the user to choose from a list of categories
</context>
<task>
add to the groupay_data.json file Categories key and a list of values like דלק, רכב, מסעדה,  etc and also אחר. in add_expense_screen.dart in על מה field change it from a free text line to a list of categories. If the user choose אחר the field פירוט becomes necessary and if the user try to save the expense an error will be displayed with the test : נדרש פירוט

</task>
<constraints>
you don't fix another bugs you find only what is related to add category in an expense.
 the task is done when you and the feature and the tests and the flutter analyze command and flutter test run without find any issues
</constraints>
<format>
return a list of files you change and the tests results
</format>
<examples>
example 1: the user add a new expense in a group and write the amount and in על מה field he choose דלק from the list and save the expense. it will saved in the groupay_data.json
example 2: the  user add a new expense in a group and write the amount and in על מה field he choose אחר the list and save the expense it will not saved and display an error massage : פירוט נדרש
example 3 : the  user add a new expense in a group and write the amount and in על מה field he choose אחר the list and in field על מה  he write קולה בתחנת דלק and save the expense. it will saved in the groupay_data.json
</examples>
```

# exercise 4 : sorting the expense list

## מטרת הפרומט

: הוספת אפשרות למיין את רשימת ההוצאות במסך הקבוצה לפי סכום, קטגוריה ומי שילם, בסדר עולה ויורד, בלי לשנות את הנתונים השמורים

## prompt:

```
In the Flutter groupo_screen.dart by disable expense list, add the ability to sort expense by amount in ascending and descending order, category order, and paid order.

The feature should allow users to change the sorting direction while preserving the original expense data. Follow the existing architecture and UI conventions.

Do not change expense editing, or persistence behavior because those features are outside this task. add only this ability and write it test

Done when:
- all sorting directions work correctly.
- Switching between them updates the displayed list.
- flutter analyze passes.
- flutter test passes.

If you notice unrelated bugs, report them in your final summary without fixing them. If none are found, state that explicitly.
return the tests result and the nsms of the files modified
```

## result:

You can now sort the expense list on the group screen by date, amount, category or payer, in either direction. `flutter analyze` is clean and all 19 tests pass.

**How it works:** above the expense list, next to "הוצאות (N)", there's a sort button that opens a menu (תאריך, סכום, קטגוריה, מי שילם) and an arrow that flips the direction.
- **Starting order:** choosing a new sort starts ascending, except date, which starts newest-first like before.
- **Category:** follows the order of the categories list. Older expenses with free-text titles come last.
- **Payer:** alphabetical by name.
- **Ties:** expenses that compare equal keep their original order.

Sorting only changes the display: the saved expenses and their order never change, and the sort resets when you leave the group screen. I read "by disable expense list" in your prompt as "the displayed expense list".

**Files modified:**
1. `lib/logic/expense_sort.dart` (new): `sortExpenses`, which returns a sorted copy and leaves the group's list unchanged.
2. `lib/screens/group_screen.dart`: holds the chosen sort and shows the sort button and direction arrow.
3. `test/expense_sort_test.dart` (new): 5 unit tests covering every sort in both directions, ties, and that the original list is unchanged.
4. `test/group_screen_test.dart`: a new widget test that goes through every sort and direction on the real screen and checks the displayed order after each switch. It also checks that the saved order is unchanged.

**Test results:**
```
flutter analyze → No issues found!
flutter test    → 19 tests, All tests passed!
```

On the first run, the widget test failed at its last step: oldest-first by date showed the list unchanged. The three test expenses were added within the same instant, so their `createdAt` times were identical. I fixed this by sorting dates by position in the saved list, which is always newest-first, so date sorting works even when times are identical.

**Unrelated bugs I noticed (not fixed):**
1. **"לכל אחד" is wrong for uneven splits:** the figure at the top of the who-owes-whom card is still the total divided by all members (`lib/widgets/settlement_card.dart:20`).
2. **Deleting a member can silently move their share to others:** `deleteMember` (`lib/state/app_state.dart`) only blocks deleting a member who paid an expense. A member who didn't pay but was selected in "עם מי מתחלק?" can be deleted, and their share then moves to the remaining participants without any warning. If every selected participant is deleted, the expense falls back to being split among everyone.


