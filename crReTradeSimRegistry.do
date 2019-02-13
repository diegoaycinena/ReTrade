*version 11
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_SimRegistry.log", replace

/* ReTrade Project (Stage II - Simulations)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Generates Registry of (wave 2) SIMULATIONS database */
/* creates SimRegistry.dta file */
/* by Diego Aycinena */
/* Created: 2018-12-27 */
/* Last modified: 2018-12-27 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */


insheet using "$path_data\Simulations\RegistroSimulations.txt", clear

gen sim_wave=2 //second wave of simulations (run by Betzy)
lab var sim_wave "Simulation wave"

*Encode and label trading institution treatment variable
capture lab def treatment 1 "CDA" 2 "UPDA"  //define same label
encode tradinginstitution, gen(institution) label(treatment)
lab var institution "Treatment (1=CDA, 2=UPDA)"

*Encode and label trading environment variable (Equilibrium surplus between net-buyers and net-sellers)
capture label define environment 0 "original" 1 "Asymetric Demand" 2 "Full Surplus Demand" -1 "Asymetric Supply" -2 "Full Surplus Supply"
encode environment, gen(x)
replace x=0 if x==3
replace x=-1 if x==2
replace x=2 if x==4
replace x=-2 if x==5
rename environment tradingenvironment
gen environment=x
lab val environment environment
label def environment 0 "Symmetric (original)", modify
label var environment "Type of Trading Environment"
drop x

*Encode and label robot intelligence treatment variable
replace robotagentintelligence = strupper("MIa") if robotagentintelligence=="MIa"  //correct case-sensitive spelling
capture lab def sim_treat 0 "ZIA" 1 "MIA"  //define same label
encode robotagentintelligence, gen(sim_treatment) label(sim_treat)
lab var sim_treatment "Simulation treatment (0=ZIA, 1=MIA)"

*Generate new variable with date-time of simulation run. Will be used to merge for meta-information
gen simrun_datetime=substr(filename,7,.)

*Generate date variable
gen long date=date(simrun_datetime, "MDYhms")
format d %dD_m_Y 

*Generate date & time variable
gen  dtime=clock(simrun_datetime, "MDYhms")
format dtime %tcDay_Mon_DD_HH:MM:SS_CCYY


order no dtime filename institution environment sim_treatment tradingperiods tradingperiodtimeseconds simrun_datetime date repeat

compress

saveold $path_data\SimRegistry, version(11) replace

x
merge m:1 session subject using $path_data\SimPay0 

assert _merge==3
drop _merge

log close
