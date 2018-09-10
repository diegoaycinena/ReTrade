*version 10
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_0.log", replace

/* ReTrade Project (Stage I)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates main database for subject level data and period level (aggregate data)*/
/* creates Summary0.dta and PeriodSummary00.dta files */
/* by Diego Aycinena */
/* Created: 2017-02-13 */
/* Last modified: 2017-09-13 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

cd "$path_data"

*variables for counter and temp files
local i=0
tempfile rawfile
tempfile sfile

//////////////////////////////
*** Read Summary Data file ***
//////////////////////////////
local FileName "Summary_Data"	
	// Summary_Data files contain the following information:
		* Subject level results for each period
		* Aggregate level period results (Subject 0, at the end of each period)
		* Periods selected for payment (PaidPeriods)
		* Quiz answers (Player	Question	Answer)
		* Payment file (Player	Name	Earnings	IP Address)

foreach FileDate of global file_date_list {

	local i=`i'+1		
	insheet using `FileName'_`FileDate'.csv, clear
	
	**********************
	**** Quiz summary ****
	**********************
	
	*drop lines that contain non quiz data
	drop if subperiod=="0" 
	drop if subperiod==""
	drop if period=="Paid Periods"
	
	*keep only string variables 
	ds, not(type string) //list non-string variables 
	drop `r(varlist)' //drop non-string variables
	
	destring subperiod, force replace
	drop if subperiod==.
	rename period Player
	destring Player, replace
	rename subperiod Question
	
	ds, has(type string)  //list string variables
	local strlist= r(varlist) // create a local list of all string variables
	local a=0 //counter
	gen attempts=. //generate variable for # of attempts to answer each question
	foreach var of local strlist {
		local a=`a'+1
		replace attempts=`a' if `var'!="" //replace # of attempts for any variable that is non empty (to get at the max # of attempts)
		rename `var' attempt`a' //rename variable according to attempt number for a particular answer submitted
	}
	gen session=`i' 
	gen session_datetime = "`FileDate'"
	order session Player Question attempts, first 
		
	compress 
	save `sfile', replace
	
	if `i'==1 {
		capture erase Quiz0.dta
		save Quiz0
	}
	else {
		append using Quiz0
		compress
		save Quiz0, replace
	}
	
	****	 *************************		***
	*	**** Experimental Results Data ****	  *
	****	 *************************		***
	
	insheet using `FileName'_`FileDate'.csv, clear
	
	gen session=`i' 
	order session, first
	
	gen session_datetime = "`FileDate'"
	
	*drop extra variable created for emply column 
	capture drop v23 
	capture drop v24 
	capture drop v25
	
	****************************************
	**** Subject level (period) Summary ****
	****************************************
	
	*drop lines that contain subject name, number, ip and earnings
	keep if subperiod=="0"
	capture drop if period==" " | period=="Name" | period=="ID"
	capture drop if beginningiventory==. & endinginventory==. & changeininventory==. & startingcash==.
	
	* destring numeric variables (read as string because of quiz text answers in the columns)
	destring period subperiod day subject, replace
	capture destring marketprice, replace
	capture destring averageprice endingprice, replace 
	foreach var of varlist beginningiventory endinginventory changeininventory volume beginningvalue endingvalue changeinvalue cash earnings step1value step1size step1endinventory step1begininventory step2value step2size step2begininventory step2endinventory {
		capture destring `var', replace
	}
	rename cash cash_change
	rename changeininventory inv_change

	assert subperiod==0
	assert day==period
	drop subperiod day
	
	save `rawfile', replace
	
	*drop period summary data
	drop if subject==0

	compress 
	save `sfile', replace

	if `i'==1 {
		capture erase Summary0.dta
		save Summary0
	}
	else {
		append using Summary0
		compress
		save Summary0, replace
	}
	
		******************************
		**** Period level summary ****
		******************************
	use `rawfile', clear
		
	*Keep period-level summary data (subject=0 --> total for period) 
	keep if subject==0 
	
	drop subject step*value step*size step*begininventory step*endinventory cash
	*Step2Value Step2Size Step2BeginInventory Step2EndInventory

	compress 
	save `sfile', replace

	if `i'==1 {
		capture: erase PeriodSummary00.dta
		compress
		save PeriodSummary00, replace
	}
	else {
		append using PeriodSummary00
		compress
		save PeriodSummary00, replace
	}
	
	**************************
	**** Pay & IP summary ****
	**************************
	if `i'!=10 {
		insheet using `FileName'_`FileDate'.csv, clear
		
		*drop non-pay file data
		drop if subperiod=="0" 
		drop if subperiod==""
		drop if period=="Paid Periods" | period=="" | period=="Player"
		gen x=real(subperiod)
		keep if x==.
		*drop x beginningiventory - step2endinventory
		rename subject ip_address
		rename period subject
		rename subperiod name
		rename day final_earnings
		drop if subject=="ID"
		keep subject name final_earnings ip_address
		destring subject, replace
		destring final_earnings, ignore($) replace
		}
	else {
		insheet using s10pay.txt, clear
		
		drop ipaddress 
		gen str15 ip_address = ""
		rename earnings final_earnings
		rename id subject
		destring final_earnings, ignore($) replace
		}

	gen session=`i' 
	order session, first
	*gen session_datetime = "`FileDate'"
	
	gen id_pay=session*100+subject  //
		
	compress
	save `sfile', replace

	if `i'==1 {
		capture erase pay0.dta"
		save pay0, replace
	}
	else {
		append using pay0
		compress
		save pay0, replace
	}	
	sort session subject
	save, replace
}

////////////////////////////////////////
*** Read ESI Psych Survey data file ***
////////////////////////////////////////
local j=0 
foreach Fname of global quest_file_list {
	local j=`j'+1		
	insheet using `Fname'_ESI.csv, clear
	gen session=`j'
	order session, first
	capture destring chapmanid, force replace
	rename num subject
	recode gender (2=0 "male")(1=1 "female"), gen(female)
	order female gender age, after(subject)
	drop gender
	compress
	
	if `j'==1 {
		capture erase Quest0.dta
		save Quest0, replace
	}
	else {
		append using Quest0
		compress
		save Quest0, replace
	}	
	
	sort session subject
	save, replace
}

*gen unique subject identifier
gen id = session*100+subject
lab var id "Subject ID (unique)"
order id, first
save, replace


*	*****************************************	*
****	All data read, now begin to merge	 ****
*	*****************************************	*

matchit id fullname using pay0.dta, idus(id_pay) txtus(name)  // use matchit command to find a match for names and ensure proper merging

egen double max_score=max(similscore) if id!=. & id_pay!=., by(id)  //find the max similarity score for each id
keep if similscore==max_score			// keep only ones with max similarity score (i.e. drop repeated with lower similarity score)
isid id
isid id_pay
*drop max_score 

gen FullName=strproper(fullname)
gen Name=strproper(name)

browse FullName Name max_score id id_pay if FullName!=Name & id!=610 & id!=1207  

assert FullName==Name if id!=610 & id!=1207   //ensure names match in both data sets, except for two case detected and corroborated (girl in session 6 who used only first name in one DB, but full name in the other; and person in session 12 who included nickname in parenthesis in on DB)
sort id_pay
merge 1:1 id_pay using pay0.dta
assert _merge==3
drop id_pay similscore FullName fullname Name _merge
sort id
save pay0, replace

use Quest0, clear
merge 1:1  id using pay0 //merge survey data with pay data
assert _merge==3
gen FullName=strproper(fullname)
gen Name=strproper(name)
assert FullName==Name if id!=610 & id!=1207 //ensure names match in both data sets, except for the one case detected and corroborated (girl in session 6 who used only first name in one DB, but full name in the other)

drop FullName fullname Name name chapmanid _merge //drop all variables personal identifiable info from data
order ip_address, last

compress

save SocioDemo.dta, replace

*Delete all datasets containing names or personal identifiable info
erase pay0.dta
erase Quest0.dta

use Quiz0, clear //create abbreviated quiz data to merge with (survey+pay) data
keep session Player Question attempts
rename Player subject
rename Question question

*gen unique subject identifier
gen id = session*100+subject
lab var id "Subject ID (unique)"
reshape wide attempts, i(id) j(question)

sort id

save `sfile', replace

use SocioDemo.dta, clear  
merge 1:1 id using `sfile' //merge quiz data with (survey+pay) data

assert _merge==3
drop _merge

compress

save SocioDemo.dta, replace 



******************************************
***	Clean and merge subject level data ***	
******************************************

use Summary0, clear
capture drop v23 v24 v25 v26

lab var session "Session #"

*Treatment Institution variables
gen treatment=.
*assert that there is always a price 
assert averageprice!=. if marketprice==.
assert marketprice!=. if averageprice==.
*need to deal with possibility of no price due to no transactions taking place in a period
replace treatment=1 if averageprice!=.
replace treatment=2 if marketprice!=.
assert treatment!=.

lab var treatment "Treatment (1=CDA, 2=UPDA)"
lab def treatment 1 "CDA" 2 "UPDA" 
lab val treatment treatment

gen upda=treatment-1
label var upda "UPDA"

gen cda = abs(2-treatment)
lab var cda "CDA"

*gen unique subject identifier
gen id = session*100+subject
lab var id "Subject ID (unique)"

order id session treatment period, first

sort session subject period

compress

merge m:1 session subject using SocioDemo.dta

assert _merge==3
drop _merge

saveold Summary0, version(11) replace


******************************************* 
***	Clean Period level (aggregate) data ***    
*******************************************

use PeriodSummary00, clear

capture drop v24 v25
drop beginningiventory endinginventory inv_change 

lab var session "Session #"

*Treatment Institution variables
gen treatment=.
*assert that there is always a price 
assert averageprice!=. if marketprice==.
assert marketprice!=. if averageprice==.
*need to deal with possibility of no price due to no transactions taking place in a period
replace treatment=1 if averageprice!=.
replace treatment=2 if marketprice!=.
assert treatment!=.

lab var treatment "Treatment (1=CDA, 2=UPDA)"
lab def treatment 1 "CDA" 2 "UPDA" 
lab val treatment treatment

gen upda=treatment-1
label var upda "UPDA"

gen cda = abs(2-treatment)
lab var cda "CDA"

gen price_avg = averageprice if cda==1
replace price_avg = marketprice if upda==1
lab var price_avg "Average Price (period)"

gen price_last = endingprice if cda==1
replace price_last = marketprice if upda==1
lab var price_last "Last Price (period)"

order treatment upda cda period price_avg price_last, after(session)

compress

saveold PeriodSummary00, version(11) replace

log close
