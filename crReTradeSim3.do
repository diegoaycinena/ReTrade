*version 11
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_Sim3.log", replace

/* ReTrade Project (Stage II - Simulations)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Reads SIMULATIONS parameter level data */ 
/* creates SimParams0.dta file and merges to create SimSummary.dta and SimPeriodSummary.dta */
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
local sim_t "zia mia"

//////////////////////////////////
*** Read Parameters Data file ***
/////////////////////////////////

local FileName "Parameters_Data"	// Action data file contains records for all individual and market actions (bids actions, asks actions, trades, etc.) in a session

foreach sim_treat of local sim_t { // run separately for ZIA and MIA

	cd "$path_data/simulations/`sim_treat'"	
	local j=0
	
	foreach FileDate of global `sim_treat'_f_date_list {

		local i=`i'+1			
		local j=`j'+1	
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
			save $path_data\SimGameSetup0.dta, replace
		}
		else {
			append using $path_data\SimGameSetup0.dta
			compress
			save $path_data\SimGameSetup0.dta, replace
		}
		sum numberOfPeriods
		local n_p = r(max)
		
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
		*replace npos1=npos1
		gen period = real(substr(v1,1,npos1))
		replace npos1=npos1+2
		gen npos2=strpos(v1,";")-npos1
		gen time  = real(substr(v1,npos1,npos2))
		*replace v_name = "p"+strtoname(v_name)
		drop v1 row npos1 npos2 
		drop if period>`n_p'
		
		gen sim_treatment = `y' // 0=zia, 1=mia
		gen sim_run = (`y'*1000)+`j'
		gen session=77000+`i' 
		order sim_run sim_treatment, first
		
		compress 
		save `sfile', replace
	
		if `i'==1 {
			save $path_data\SimPeriodTime0.dta, replace
		}
		else {
			append using $path_data\SimPeriodTime0.dta
			compress
			sort sim_run session period
			save $path_data\SimPeriodTime0.dta, replace
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
	local y=`y'+1 
}
	********
cd $path_data

use $path_data\SimPeriodTime0.dta, clear
merge m:1 sim_run session using $path_data\SimGameSetup0.dta  //merge to create SimParams0.dta

assert _merge==3
drop _merge

drop if period>numberOfPeriods  //drop period specific parameters for periods beyond the number of periods that the simmulation ran for

compress

lab var time "Period duration (seconds)"
lab var numberOfPlayers "Number of traders"
lab var numberOfPeriods "Number of periods in session"
lab var testMode "Simulation"
lab var marketType "Market Institution"
lab var practicePeriods "Number of practice periods"
lab var paidPeriodCount "Number of paid periods"

rename time time_period

save $path_data\SimParams0.dta, replace

*
use $path_data\SimPeriodSummary0.dta, clear //prepare to merge with Period Summary data

sort sim_run session period
egen maxP=max(period), by(session)

merge 1:1 sim_run session period using $path_data\SimParams0.dta  //merge

assert maxP==numberOfPeriods
drop maxP

assert _merge==3
drop _merge

lab var sim_treat "Simulation treatment (0=ZIA, 1=MIA)"
lab def sim_treat 0 "ZIA" 1 "MIA"
lab val sim_treat sim_treat
lab var sim_run "Simulation run #"

compress 

save $path_data\SimPeriodSummary.dta, replace

*tab 
use $path_data\SimSummary0.dta, clear //prepare to merge with Summary data

sort sim_run session period
egen maxP=max(period), by(session)

merge m:1 sim_run session period using $path_data\SimParams0.dta  //merge

assert _merge==3
drop _merge

assert maxP==numberOfPeriods
drop maxP

compress 
save $path_data\SimSummary.dta, replace

log close
