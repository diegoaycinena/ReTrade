*version 10
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_1.log", replace

/* ReTrade Project (Stage I)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates individual action level (bids, asks, trades, etc.) data */
/* by Diego Aycinena */
/* Created: 2017-06-07 */
/* Last modified: 2017-09-12 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */


cd "$path_data"

*variables for counter and temp files
local i=0
tempfile AppFile
tempfile sfile

//////////////////////////////
*** Read Action Data file ***
//////////////////////////////

local FileName "Action_Data"	// Action data file contains records for all individual and market actions (bids actions, asks actions, trades, etc.) in a session
foreach FileDate of global file_date_list {
	insheet using "$ServerData_path/`FileName'_`FileDate'.csv", clear
	local i=`i'+1
	
	gen session=`i' 
	order session, first
	
	gen session_datetime = "`FileDate'"

	compress 
	save `sfile', replace

	if `i'==1 {
		save `AppFile'
	}
	else {
		append using `AppFile'
		compress
		save `AppFile', replace
	}
	clear
}

use `AppFile', clear

assert market==period
assert subperiod==0
drop market subperiod 

*drop extra variable created for emply column (v18)
capture: drop v18 
capture: drop v19 
capture: drop v20 
capture: drop v21 
capture: drop v22
tab action

lab var session "Session #"

*Define Value Labels
lab def truefalse 0 "False" 1 "True"
lab def action 1 "Bid" -1 "Retract Bid" 3 "Offer" -3 "Retract Offer" 10 "Trade" 2 "Open Cross" -98 "Tentative Cross" 

encode auto, gen(automatic) label(truefalse)
order automatic, after(auto)
drop auto

encode action, gen(actiontype) label(action) 
lab var actiont "Type of action" 
order actiont, after(action)
drop action

*Treatment Institution variables
gen treatment=.
replace treatment=1 if side==""
replace treatment=2 if tradecount==. 
assert treatment!=. //need to deal with possibility of no price due to no transactions taking place in a period

lab var treatment "Treatment (1=CDA, 2=UPDA)"
lab def treatment 1 "CDA" 2 "UPDA" 
lab val treatment treatment

gen upda=treatment-1
label var upda "UPDA"

gen cda = abs(2-treatment)
lab var cda "CDA"

rename player subject

*gen unique subject identifier
gen id = session*100+subject
lab var id "Subject ID (unique)"

rename time timeleft
lab var timeleft "Time remaining in period (seconds)"

gen time = 120-time
lab var time "time (in seconds)"

order id session treatment period, first
order session_datetime bidqueue offerqueue trades tentativebids tentativeoffers openbids openoffers, last
order actiontype buyervalue price  sellervalue currentprice tradecount , after(subject)

egen totalBids=count(bidid) if actiontype==1 & automatic==0, by(session period)
lab var totalBids "Total period Bids"
egen totalOffers=count(offerid) if actiontype==3 & automatic==0, by(session period)
lab var totalOffers "Total period Offers"
 
compress

//Drop data from session 3 (problems with client software, see log)
drop if session==3 & session_datetime=="5-15-2017_11_31_41"

save Action0, replace
drop bidqueue offerqueue trades tentativebids tentativeoffers openoffers
saveold Action_old_11, version(11) replace

use Action0, clear
	
log close
