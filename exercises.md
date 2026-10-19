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


