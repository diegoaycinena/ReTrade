
cd "$path_data"

use Summary, clear
*use SimSummary0, clear


egen NumPeriods = max(period), by(session)
gen SecondHalf = 0
replace SecondHalf=period>(NumPeriods/2)
gen Half=SecondHalf+1 if period>0
 
keep if period>0


gen NetBuyer =( endinginventory> beginningiventory)
gen NetSeller =( endinginventory< beginningiventory)

gen FinalUnits=endinginventory

gen TransactProfit = cash_change

*Competitive Equilibrium Predictions
gen predNetBuyerEq =(step1value>105)
gen predNetSellerEq =(step1value<105)

gen predFinalUnitsEq = 1 + predNetBuyer - predNetSeller
*replace predFinalUnitsEq = 2 if predNetBuyer==1
*replace predFinalUnitsEq = 0 if predNetSeller==1

gen fUnitsDeviation=FinalUnits- predFinalUnits

gen rightRoleEq=0
replace rightRoleEq= 1 if predNetBuyer==NetBuyer
replace rightRoleEq=1 if predNetSeller==NetSeller
replace rightRoleEq=1 if step1value==105 & endinginventory== beginningiventory


*Best (better?) response predictions
gen predNetBuyer =(step1value>averageprice)

gen predNetSeller =(step1value<averageprice)


gen rightDirRole = (TransactProfit>0)
replace rightDirRole = 1 if TransactProfit==0 & step1value==averageprice


**Error types
*gen 
gen WrongRole=0 & upda==1
replace WrongRole = 1 if (step1value>marketprice & NetSeller==1) & upda==1
replace WrongRole = 1 if (step1value<marketprice & NetBuyer==1) & upda==1 

gen NoRole=0 if upda==1
replace NoRole = 1 if (step1value<marketprice & inv_change==0) & upda==1
replace NoRole = 1 if (step1value>marketprice & inv_change==0) & upda==1 

gen wrongrole = WrongRole
replace wrongrole = 1 if (step1value>averageprice & NetSeller==1) & cda==1
replace wrongrole = 1 if (step1value<averageprice & NetBuyer==1) & cda==1 

gen norole = 0
replace norole = NoRole if upda==1
replace norole = 1 if (step1value<averageprice & inv_change==0) & cda==1
replace norole = 1 if (step1value>averageprice & inv_change==0) & cda==1 

gen overbought=0
replace overbought=1 if endinginventory>2

*gen all_errors= wrongrole * overbought
gen errors = wrongrole + overbought + norole
gen any_error = (errors>0)

*tab treat Half, sum(all_err) nofreq nost

tab treat Half, sum(any_error) nofreq nost


tab treat Half, sum(overbought ) nofreq nost
tab treat Half, sum(wrongrole  ) nofreq nost

tab treat Half, sum(norole  ) nofreq nost

preserve
x
collapse (sum) any_error errors wrongrole overbought norole rightDirRole predNetSeller predNetBuyer fUnitsDeviation predNetSellerEq predNetBuyerEq TransactProfit earnings NetSeller NetBuyer endingvalue beginningvalue changeinvalue volume (mean) marketprice averageprice endingprice  (median) upda cda treatment ,by(session period)

lab val treatment treatment

gen Any_Error = (errors>0)
gen No_Errors = 1-Any_Err
gen All_Error = wrongrole * overbought * norole 

tab period treat, sum(wrongrole) nofreq nost
tab period treat, sum(norole) nofreq nost
tab period treat, sum(overbought) nofreq nost

tab period treat, sum(All_Err) nofreq nost
tab period treat, sum(Any_Err) nofreq nost

tab period treat, sum(wrongrole) nofreq nost
tab period treat, sum(overbought) nofreq nost

gen type_error = 1 


x

*************************************
*************************************
*************************************
*****	Analyze Simulations 	*****
*************************************
*************************************
*************************************


cd "$path_data"

use SimSummary0, clear


gen NetBuyer =( endinginventory> beginningiventory)
gen NetSeller =( endinginventory< beginningiventory)

gen FinalUnits=endinginventory

gen TransactProfit = cash_change

*Competitive Equilibrium Predictions
gen predNetBuyerEq =(step1value>105)
gen predNetSellerEq =(step1value<105)

gen predFinalUnitsEq = 1 + predNetBuyer - predNetSeller
*replace predFinalUnitsEq = 2 if predNetBuyer==1
*replace predFinalUnitsEq = 0 if predNetSeller==1

gen fUnitsDeviation=FinalUnits- predFinalUnits

gen rightRoleEq=0
replace rightRoleEq= 1 if predNetBuyer==NetBuyer
replace rightRoleEq=1 if predNetSeller==NetSeller
replace rightRoleEq=1 if step1value==105 & endinginventory== beginningiventory


*Best (better?) response predictions
gen predNetBuyer =(step1value>averageprice)

gen predNetSeller =(step1value<averageprice)


gen rightDirRole = (TransactProfit>0)
replace rightDirRole = 1 if TransactProfit==0 & step1value==averageprice


**Error types
*gen 
gen WrongRole=0 & upda==1
replace WrongRole = 1 if (step1value>marketprice & NetSeller==1) & upda==1
replace WrongRole = 1 if (step1value<marketprice & NetBuyer==1) & upda==1 

gen NoRole=0 if upda==1
replace NoRole = 1 if (step1value<marketprice & inv_change==0) & upda==1
replace NoRole = 1 if (step1value>marketprice & inv_change==0) & upda==1 

gen wrongrole = WrongRole
replace wrongrole = 1 if (step1value>averageprice & NetSeller==1) & cda==1
replace wrongrole = 1 if (step1value<averageprice & NetBuyer==1) & cda==1 

gen norole = 0
replace norole = NoRole if upda==1
replace norole = 1 if (step1value<averageprice & inv_change==0) & cda==1
replace norole = 1 if (step1value>averageprice & inv_change==0) & cda==1 

gen overbought=0
replace overbought=1 if endinginventory>2

*gen all_errors= wrongrole * overbought
gen errors = wrongrole + overbought + norole
gen any_error = (errors>0)

tab treat sim_treat, sum(any_error) nofreq nost


tab treat sim_treat, sum(overbought ) nofreq nost
tab treat sim_treat, sum(wrongrole  ) nofreq nost

tab treat sim_treat, sum(norole  ) nofreq nost


