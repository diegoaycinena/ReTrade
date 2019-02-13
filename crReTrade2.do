*version 10
set more off
capture log close
log using "$my_path\ReTrade\ReTrade2\Log\do-crReTrade2_2.log", replace

/* ReTrade Project (wave II)*/
/* Re-Trading, Price Discovery and Efficiency under Alternative Exchange Institutions */
/* Check Market quantities and prices and fix price for UPDA in PeriodSummary data */
/* creates PeriodSummary0.dta file (using Summary0.dta and PeriodSummary00.dta) */
/* by Diego Aycinena */
/* Created: 2017-05-23 */
/* Last modified: 2017-06-16 */
/* located in C:\...\Dropbox\Research\data\ReTrade\do */

cd "$path_data"

use Summary0, clear  //Use trader-period summary data to start

*Generate period level totals & wieghted averages
egen TotVol=total(volume), by(session period)
gen wPavg=averageprice*volume/TotVol
gen wPmkt=marketprice*volume/TotVol


gen price_avg=averageprice if cda==1
replace price_avg=marketprice if upda==1
tab treat period, sum(price_avg)

gen price_last=endingprice if cda==1
replace price_last=marketprice if upda==1
tab treat period, sum(price_last)


collapse treatment averageprice marketprice  TotVol cda upda (sum) wPavg wPmkt volume TotEarnings=earnings, by(session period)
assert TotVol==volume
drop volume

compare wPmkt marketprice if upda==1 
gen abs_dev = abs(wPmkt-marketprice)
assert abs_dev<.01 if abs_dev!=.
drop marketprice abs_dev

gen price_avg=wPavg if cda==1
replace price_avg=wPmkt if upda==1
lab var price_avg "mean transaction Price" 

keep session period TotVol price_avg wPavg wPmkt TotEarnings
sort session period
compress
tempfile tfile
save `tfile'

use PeriodSummary00.dta, clear
sort session period

*price registered in wrong column (earnings) for UPDA
replace marketprice=earnings if upda==1
replace price_avg=earnings if upda==1
replace price_last=earnings if upda==1

merge 1:1 session period using `tfile'

assert _merge==3
drop _merge

replace TotVol=TotVol/2
assert TotVol==volume
drop TotVol

assert wPmkt!=. if upda==1
assert wPmkt==0 if cda==1
assert abs(price_avg-averageprice)<0.01 if cda==1
assert price_last==endingprice if cda==1

compare wPavg averageprice if cda==1
gen abs_dev = abs(wPavg-averageprice)
assert abs_dev<.1 if abs_dev!=.
drop wPavg abs_dev

*price registered in wrong column (earnings) for UPDA
gen mpriceabsdif=abs(wPmkt-earnings) if upda==1 //gen absolute value of differennce
assert mpriceabsdif<0.01 if upda==1 //assert that difference is arbitrarily small 

*replace marketprice=wPmkt if upda==1
drop wPmkt mpriceabsdif

*price registered in wrong column (earnings) for UPDA [manually checked in addition to check above]
replace marketprice=earnings if upda==1

assert price_avg==marketprice if upda==1

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

save PeriodSummary0.dta, replace

/*
tab treat, sum(price_avg)
*/


use Action0, clear

keep session period treatment upda cda totalBids totalOffers
collapse treatment upda cda totalBids totalOffers, by(session period)

lab var totalBids "Total period Bids"
lab var totalOffers "Total period Offers"

gen totalAction = totalBids + totalOffers
lab var totalAction "Total period bids + asks"

sort session period
save `sfile'.dta, replace

use PeriodSummary0.dta, clear
sort session period
merge 1:1 session period using `sfile'.dta

assert _merge==3
drop _merge

compress 

save PeriodSummary0.dta, replace

log close
