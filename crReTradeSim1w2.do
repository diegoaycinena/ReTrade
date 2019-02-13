*version 11
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_Sim1w2.log", replace

/* ReTrade Project (Stage II - Simulations)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates SIMULATIONS (wave 2) action level (bids, asks, trades, etc.) database */ 
/* creates SimAction0w2.dta file */
/* by Diego Aycinena */
/* Created: 2087-12-30 */
/* Last modified: 2018-12-31 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

clear

*variables for counter and temp files
local i=0
local y=0
local r=0
tempfile AppFile
tempfile sfile
local sim_t "zia mia"

//////////////////////////////
*** Read Action Data file ***
//////////////////////////////

local FileName "Action_Data"	// Action data file contains records for all individual and market actions (bids actions, asks actions, trades, etc.) in a session


foreach sim_treat of local sim_t { // run separately for ZIA and MIA

	cd "$path_RawSimData/`sim_treat'"	
	local j=0
	
	foreach FileDate of global `sim_treat'_f_date_listW2 {

		local i=`i'+1			
		local j=`j'+1	
		capture insheet using `FileName'_`FileDate'.csv, clear
		if _rc==601 {	// if error due to missing file, account for that
			local r=`r'+1
			display "i=`i', MISSING FILE #`r': `FileName'_`FileDate', `sim_treat'" 
		}
		else {			//if file is not missing
			*display "i=`i', `FileDate', `sim_treat'"  //for debugging mode
		
			capture drop tentativebids tentativeoffers openbids openoffers //drop UPDA variables which may make datasets too large to handle 
			capture drop bidqueue offerqueue trades //drop CDA variables which may make datasets too large to handle

			gen sim_treatment = `y' // 0=zia, 1=mia
			gen sim_run = (`y'*1000)+`j'
			gen session=77000+`i' 
			order sim_run sim_treatment, first
	
			gen simrun_datetime = "`FileDate'"
			gen  dtime=clock(simrun_datetime, "MDYhms")
			format dtime %tcDay_Mon_DD_HH:MM:SS_CCYY
		
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
		}
		clear
	}
	local y=`y'+1 
}
**************************************************************

use `AppFile', clear
replace period = market if market==period-1
drop if market!=period & subperiod==. & time==. & player==. & bidid==. & offerid==. & tradecount==. // 2 out of 24,503,071 observations
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

*rename time timeleft
*lab var timeleft "Time remaining in period (seconds)"

*gen time = 120-time
*lab var time "time (in seconds)"

order id session treatment period, first
*order session_datetime bidqueue offerqueue trades tentativebids tentativeoffers openbids openoffers, last
order actiontype buyervalue price  sellervalue currentprice tradecount , after(subject)

egen totalBids=count(bidid) if actiontype==1 & automatic==0, by(sim_run session period)
lab var totalBids "Total period Bids"
egen totalOffers=count(offerid) if actiontype==3 & automatic==0, by(sim_run session period)
lab var totalOffers "Total period Offers"

compress
save $path_data\SimAction0w2, replace
capture drop bidqueue offerqueue trades tentativebids tentativeoffers openoffers
saveold $path_data\SimActionw2_old_11, version(11) replace

use $path_data\SimAction0w2, clear
	
log close
