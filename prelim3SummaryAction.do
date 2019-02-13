

use $path_data\Action0, clear

egen NumPeriods = max(period), by(session)
gen SecondHalf = 0
replace SecondHalf=period>(NumPeriods/2)
gen Half=SecondHalf+1 if period>0


replace period=period-2
replace period=period-1 if period<1 

assert period<=15 
keep if period>0

numlabel treatment, add
numlabel action, add

egen volume=max(tradecount), by(session period)
gen vol_pct = (tradecount)/(volume+0.5)
gen x=period+vol_pct

twoway scatter price x if actiontype==10 & cda==1, by(session, legend(off) title("Transaction Prices CDA (by session)") note("Prices for all transactions by period for each session")) m(oh) msize(tiny)  yline(100, lwidth(med) lpattern(_) lcolor(gs1)) yline(110, lwidth(med) lpattern(_) lcolor(gs1))   xline(1, lwidth(vthin) lcolor(gs12)) xline(2, lwidth(vthin) lcolor(gs12)) xline(3, lwidth(vthin) lcolor(gs12)) xline(4, lwidth(vthin) lcolor(gs12)) xline(5, lwidth(vthin) lcolor(gs12)) xline(6, lwidth(vthin) lcolor(gs12)) xline(7, lwidth(vthin) lcolor(gs12)) xline(8, lwidth(vthin) lcolor(gs12)) xline(9, lwidth(vthin) lcolor(gs12)) xline(10, lwidth(vthin) lcolor(gs12)) xline(11, lwidth(vthin) lcolor(gs12)) xline(12, lwidth(vthin) lcolor(gs12)) xline(13, lwidth(vthin) lcolor(gs12)) xline(14, lwidth(vthin) lcolor(gs12)) xline(15, lwidth(vthin) lcolor(gs12)) scheme(s1mono)

x

gen lossbid = 0 if action==1 & automatic==0
replace lossbid=1 if action==1 & price > buyervalue  & automatic==0
lab var lossbid "Bid at loss (potential)"

gen lossask=0 if action==3 & automatic==0
replace lossask=1 if action==3 & price < sellervalue & automatic==0
lab var lossask "Offer at loss (potential)"

gen lbmagnitude = price - buyervalue if lossbid==1 & automatic==0
lab var lbmagnitude "Max magnitude of loss for bid"

gen lamagnitude = sellervalue - price if lossask==1  & automatic==0
lab var lamagnitude "Max magnitude of loss for offer"

sort session period bidid time offerid 
gen rlossbid = 0 if action==-1 & automatic==0 & automatic==0
replace rlossbid=1 if action==-1  & automatic==0 & price[_n-1] > buyervalue[_n-1] & automatic==0
lab var rlossbid "Retractede (potential) loss bid"

gen rlbmagnitude = price[_n-1] - buyervalue[_n-1] if rlossbid==1  & automatic==0
lab var rlbmagnitude "Max magnitude of loss for retracted bid"

sort session period offerid time bidid
gen rlossask = 0 if action==-3 & automatic==0 & automatic==0
replace rlossask=1 if action==-3  & automatic==0 & price[_n-1] < sellervalue[_n-1] & automatic==0
lab var rlossask "Retractede (potential) loss bid"

gen rlamagnitude = sellervalue[_n-1] - price[_n-1] if rlossask==1 & automatic==0
lab var rlamagnitude "Max magnitude of loss for retracted offer"


sort session period time

gen lossbuy = 0 if action==10 & price > buyervalue
*replace 

gen losssell = 0 if action==10 & price < buyervalue



numlabel treatment, remove

egen Lbid=mean(lossbid), by(period treatment)
lab var Lbid "Proportion of bids at (potential) loss" 
egen Lask=mean(-lossask), by(period treatment)
lab var Lask "Proportion of offers at (potential) loss" 
twoway bar Lbid Lask period, by(treatment, title("Proportion of potentially losing bids and asks")) legend(row(2))

twoway (scatter lbmagnitude lamagnitude period, by(treatment) yaxis(2) msymbol(Dh Oh) msize(med)) (scatter rlbmagnitude rlamagnitude period, by(treatment) yaxis(2) msymbol(D O) msize(med))

sort period
replace Lask=-Lask
twoway (line Lbid Lask period, by(treatment, title("Proportion of potentially losing bids and asks")) lwidth(thick thick) legend(row(2) size(small)) yaxis(1)) (scatter lbmagnitude lamagnitude period, by(treatment) yaxis(2) msymbol(b o) msize(small))

