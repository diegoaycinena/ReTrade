*version 11
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_3.log", replace

/* ReTrade Project (Stage I)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Reads parameter level data */ 
/* creates Params0.dta file and merges to create Summary.dta and PeriodSummary.dta */
/* by Diego Aycinena */
/* Created: 2017-06-16 */
/* Last modified: 2017-06-16 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

clear

*variables for counter and temp files
local i=0
local y=0
tempfile sfile
tempfile tfile


cd "$path_data"

//////////////////////////////////
*** Read Parameters Data file ***
/////////////////////////////////

local FileName "Parameters_Data"	// Parameters data file contains the global and individual/period level parameters used in an experimental session

foreach FileDate of global file_date_list {
	local i=`i'+1			
	insheet using `FileName'_`FileDate'.csv, clear
	gen row = _n
		
	save `tfile'.dta, replace
	
	****************************************
**** Game Setup parameters [gameSettings]  ****
	****************************************	
	keep if row<=25
	drop if row==1
	
	gen npos=strpos(v1,"=")
	replace npos=npos-1
	gen v_name = substr(v1,1,npos)
	replace npos=npos+2
	gen v_val  = substr(v1,npos,.)
	
	drop v1 row npos 
	order v_name v_val, first
	sxpose, clear force destring firstnames //transpose
	drop gameName port instructionX instructionY windowX windowY graphMin graphMax graphQuantity
		
	gen session=`i' 
	order session, first
	
	gen session_datetime = "`FileDate'"
		
	compress 
	save `sfile', replace
	
	if `i'==1 {
		save GameSetup0.dta, replace
	}
	else {
		append using GameSetup0.dta
		compress
		save GameSetup0.dta, replace
	}
		
	************************************
**** Period Setup parameters [period]  ****
	************************************	
	use `tfile'.dta, clear
	keep if row>25
	drop if row==26
	gen irrelevant=1 if v1=="[player1]"
	replace irrelevant=1 if irrelevant[_n-1]==1
	drop if irrelevant==1
	drop irrelevant
		
	gen npos1=strpos(v1,"=")-1
	gen period = real(substr(v1,1,npos1))
	replace npos1=npos1+2
	gen npos2=strpos(v1,";")-npos1
	gen time  = real(substr(v1,npos1,npos2))

	drop v1 row npos1 npos2 
	
		
	gen session=`i' 
	order session, first
	
	gen session_datetime = "`FileDate'"	
	
	compress 
	save `sfile', replace

	if `i'==1 {
		save PeriodTime0.dta, replace
	}
	else {
		append using PeriodTime0.dta
		compress
		sort session period
		save PeriodTime0.dta, replace
	}
	
	**************************************
**** Player Setup parameters [player i]  ****
	**************************************	

	//info already containd in period data
	
	
	*******************************************
**** Exchange Rate parameters [exchangeRate]  ****
	*******************************************		
	
	*dont really need it now...
		
	clear
}
	
cd "$path_data"

use PeriodTime0.dta, clear

merge m:1 session using GameSetup0.dta  //merge to create Params0.dta

assert _merge==3
drop _merge

drop if period>numberOfPeriods  //drop period specific parameters for periods beyond the number of periods that the experiment ran for

compress

lab var time "Period duration (seconds)"
lab var numberOfPlayers "Number of traders"
lab var numberOfPeriods "Number of periods in session"
lab var testMode "Simulation"
lab var marketType "Market Institution"
lab var practicePeriods "Number of practice periods"
lab var paidPeriodCount "Number of paid periods"

rename time time_period

order session period time_period numberOfPlayers numberOfPeriods testMode marketType practicePeriods paidPeriodCount session_datetime, first 

save Params0.dta, replace  // Params0.dta data set

use PeriodSummary0.dta, clear //prepare to merge with Period Summary data

sort session period
egen maxP=max(period), by(session)

merge 1:1 session period using Params0.dta  //merge

assert maxP==numberOfPeriods
drop maxP

assert _merge==3
drop _merge

*renumber periods so that the 2 practice periods are coded as negative
replace period=period-practicePeriods if practicePeriods>=0 & practicePeriods!=.
replace period=period-1 if period<1 & practicePeriods>0 & practicePeriods!=.

compress 

save PeriodSummary.dta, replace


use Summary0.dta, clear //prepare to merge with Summary data

sort session period
egen maxP=max(period), by(session)

merge m:1 session period using Params0.dta  //merge

assert _merge==3
drop _merge

assert maxP==numberOfPeriods
drop maxP

*renumber periods so that the 2 practice periods are coded as negative
replace period=period-practicePeriods if practicePeriods>=0 & practicePeriods!=.
replace period=period-1 if period<1 & practicePeriods>0 & practicePeriods!=.

compress 

save Summary.dta, replace

log close
