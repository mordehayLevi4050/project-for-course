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


