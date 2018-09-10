*version 10
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_Sim2.log", replace

/* ReTrade Project (Stage II - Simulations)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Check Market quantities and prices and fix price for UPDA in SimPeriodSummary data */
/* creates SimPeriodSummary0.dta file (using SimSummary0.dta and SimPeriodSummary00.dta) */
/* by Diego Aycinena */
/* Created: 2017-05-23 */
/* Last modified: 2017-06-16 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

cd $path_data

use $path_data\SimSummary0, clear  //Use trader-period summary data to start

*Generate period level totals & wieghted averages
egen TotVol=total(volume), by(session period)
gen wPavg=averageprice*volume/TotVol
gen wPmkt=marketprice*volume/TotVol

/*gen price_avg=averageprice if cda==1
replace price_avg=marketprice if upda==1
tab treat period, sum(price_avg)

gen price_last=endingprice if cda==1
replace price_last=marketprice if upda==1
tab treat period, sum(price_last)
*/
collapse treatment averageprice marketprice  TotVol cda upda session sim_treat (sum) wPavg wPmkt volume TotEarnings=earnings, by(sim_run period)
assert TotVol==volume
drop volume

compare wPmkt marketprice if upda==1 
gen abs_dev = abs(wPmkt-marketprice)
assert abs_dev<.1 if abs_dev!=.
drop marketprice abs_dev

gen price_avg=wPavg if cda==1
replace price_avg=wPmkt if upda==1
lab var price_avg "mean transaction Price" 

keep sim_run sim_treat session period TotVol price_avg wPavg wPmkt TotEarnings
sort session period
compress
tempfile tfile
save `tfile'

use $path_data\SimPeriodSummary00.dta, clear
sort sim_run session period

merge 1:1 sim_run session period using `tfile'

assert _merge==3
drop _merge

replace TotVol=TotVol/2
assert TotVol==volume
drop TotVol

assert wPmkt!=. if upda==1
assert wPmkt==0 if cda==1
assert price_avg==averageprice if cda==1
assert price_last==endingprice if cda==1

compare wPavg averageprice if cda==1
gen abs_dev = abs(wPavg-averageprice)
assert abs_dev<.1 if abs_dev!=.
drop wPavg abs_dev

*price likely registered in wrong column (earnings) for UPDA
gen mpriceabsdif=abs(wPmkt-earnings) if upda==1 //gen absolute value of differennce
assert mpriceabsdif<0.1 if upda==1 //assert that difference is arbitrarily small 
replace marketprice=wPmkt if upda==1
drop wPmkt mpriceabsdif

replace price_avg = marketprice if upda==1

replace price_last = marketprice if upda==1

assert TotEarnings==earnings if cda==1 //fix earnings for UPDA
replace earnings=TotEarnings if upda==1
drop TotEarnings
assert earnings==endingvalue
drop earnings

lab var marketprice "Final Market Price (UPDA)"
lab var averageprice "Average Transaction Price (CDA)"
lab var endingprice "Last Transaction Price (CDA)"

order marketprice, before(averageprice)

compress 
save $path_data\SimPeriodSummary0.dta, replace


use $path_data\SimAction0, clear

collapse treatment upda cda sim_treatment totalBids totalOffers, by(sim_run session period)

lab var totalBids "Total period Bids"
lab var totalOffers "Total period Offers"

gen totalAction = totalBids + totalOffers
lab var totalAction "Total period bids + asks"

sort sim_run session period
save `sfile'.dta, replace

use $path_data\SimPeriodSummary0.dta, clear
sort sim_run session period
merge 1:1 sim_run session period using `sfile'.dta

assert _merge==3
drop _merge

compress 
save $path_data\SimPeriodSummary0.dta, replace

log close
