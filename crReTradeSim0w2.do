*version 11
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_Sim0w2.log", replace

/* ReTrade Project (Stage II - Simulations)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates main SIMULATIONS wave2 database for subject level data and period level (aggregate data)*/
/* creates SimSummary0w2.dta and SimPeriodSummary00w2.dta files */
/* by Diego Aycinena */
/* Created: 2018-12-26 */
/* Last modified: 2018-12-31 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

clear

*variables for counter and temp files
local i=0
local y=0
local r=0
tempfile rawfile
tempfile sfile
local sim_t "zia mia"

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

		****	 *************************		***
		*	**** Experimental Results Data ****	  *
		****	 *************************		***
			gen sim_treatment = `y' // 0=zia, 1=mia
			gen sim_run = (`y'*1000)+`j'
			gen session=77000+`i' 
			order sim_run sim_treatment, first
	
			gen simrun_datetime = "`FileDate'"
			gen  dtime=clock(simrun_datetime, "MDYhms")
			format dtime %tcDay_Mon_DD_HH:MM:SS_CCYY
	
			*drop extra variable created for emply column 
			capture drop v23 
			capture drop v24 
			capture drop v25
		
		****************************************
		**** Subject level (period) Summary ****
		****************************************
	
			*drop lines that contain subject name, number, ip and earnings
			capture destring subperiod, replace force
			keep if subperiod==0  
			capture destring period, replace 
			capture drop if period==. //" " | period=="Name" | period=="ID"
			capture drop if beginningiventory==. & endinginventory==. & changeininventory==. & startingcash==.
		
			* destring numeric variables (read as string because of quiz text answers in the columns)
			destring period subperiod day subject, replace
			capture destring marketprice, replace
			capture destring averageprice endingprice, replace 
			capture destring changeinvalue, replace force
			foreach var of varlist beginningiventory endinginventory changeininventory volume beginningvalue endingvalue changeinvalue cash earnings step1value step1size step1endinventory step1begininventory step2value step2size step2begininventory step2endinventory {
				capture destring `var', replace
			}	
			rename cash cash_change
			rename changeininventory inv_change	
	
			assert subperiod==0
			assert day==period if subject!=.
			drop subperiod day
		
			save `rawfile', replace
			
			*drop period summary data
			drop if subject==0
		
			compress 
			save `sfile', replace
		
			*display "i=`i', `FileDate'"  //for debugging mode
	
			if `i'==1 {
				capture erase $path_data\SimSummary0w2.dta
				save $path_data\SimSummary0w2
			}
			else {
				append using $path_data\SimSummary0w2
				compress
				save $path_data\SimSummary0w2, replace
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
				capture erase $path_data\SimPeriodSummary00w2.dta
				compress
				save $path_data\SimPeriodSummary00w2, replace
			}
			else {
				append using $path_data\SimPeriodSummary00w2
				compress
				save $path_data\SimPeriodSummary00w2, replace
			}
		
/*	**************************
	**** Pay & IP summary ****
	**************************
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
		
		
		gen sim_treatment = `y' // 0=zia, 1=mia
		gen sim_run = (`y'*1000)+`j'
		gen session=77000+`i' 
		order sim_run sim_treatment, first
	
		display "`FileDate' `sim_t'"
	
		gen simrun_datetime = "`FileDate'"
		gen  dtime=clock(simrun_datetime, "MDYhms")
		capture format dtime %tcDay_Mon_DD_HH:MM:SS_CCYY

		compress
		save `sfile', replace
	
		if `i'==1 {
			capture erase $path_data\SimPay0w2.dta"
			save $path_data\SimPay0w2, replace
		}
		else {
			append using $path_data\SimPay0w2
			compress
			save $path_data\SimPay0w2, replace
		}	
		sort session subject
		save, replace
*/
		}
	}
	local y=`y'+1
	
}

*drop name
*gen unique subject identifier
*gen id = session*100+subject
*lab var id "Subject ID (unique)"
*order id, first
*order ip_address, last
compress
save, replace


*	*****************************************	*
****	All data read, now clean and merge	 ****
*	*****************************************	*

***	Clean and merge subject level data ***	

use $path_data\SimSummary0w2, clear
capture drop v23 v24 v25 v26

lab var session "Session #"

*Treatment Institution variables
gen treatment=.
*need to deal with possibility of no price due to no transactions taking place in a period
drop if averageprice==. & marketprice==.  // drops 33 out of 1,668,350 observations
*assert that there is always a price 
assert averageprice!=. if marketprice==.
assert marketprice!=. if averageprice==.

replace treatment=1 if averageprice!=.
replace treatment=2 if marketprice!=.
replace treatment=treatment[_n-1] if treatment==. 
assert treatment!=.

lab var sim_treatment "Simulation treatment (0=ZIA, 1=MIA)"
lab def sim_treat 0 "ZIA" 1 "MIA"
lab val sim_treat sim_treat

lab var treatment "Treatment (1=CDA, 2=UPDA)"
lab def treatment 1 "CDA" 2 "UPDA" 
lab val treatment treatment

gen upda=treatment-1
label var upda "UPDA"

gen cda = abs(2-treatment)
lab var cda "CDA"

gen zia=1-sim_treat 
replace zia=1 if sim_treat==0
lab var zia "ZIA"

gen mia=sim_treat
lab var mia "MIA"

*gen unique subject identifier
gen id = session*100+subject
lab var id "Subject ID (unique)"

order sim_treat sim_run id session treatment period, first

sort sim_run session subject period

compress

*merge m:1 session subject using $path_data\SimPay0w2 

*assert _merge==3
*drop _merge

saveold $path_data\SimSummary0w2, version(11) replace



***	Clean Period level (aggregate) data ***    

use $path_data\SimPeriodSummary00w2, clear

capture drop v24 v25
drop beginningiventory endinginventory inv_change 

lab var session "Session #"

*Treatment Institution variables
gen treatment=.
*need to deal with possibility of no price due to no transactions taking place in a period
drop if averageprice==. & marketprice==.  //88,340 observations
*assert that there is always a price 
assert averageprice!=. if marketprice==.
assert marketprice!=. if averageprice==.

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

saveold $path_data\SimPeriodSummary00w2, version(11) replace

log close
