


cd "$path_data"
use PeriodSummary, clear
*browse treatment price_avg price_last marketprice earnings averageprice endingprice

numlabel treatment, add

egen NumPeriods = max(period), by(session)
assert NumPeriods == numberOfPeriods-practicePeriods

gen SecondHalf = 0
replace SecondHalf=period>(NumPeriods/2)
gen Half=SecondHalf+1 if period>0
 
keep if period>0

gen maxvalue = 1450
gen Efficiency_gain = ( endingvalue - beginningvalue)/( maxvalue - beginningvalue)
lab var Efficiency_gain "Efficiency gain (relative to initial allocation)"
lab var Efficiency_gain "Efficiency gain (loss)"

histogram Effi if period>0, by(treatment, title("Efficiency Gains (losses)") subtitle("(All paid periods)") note(Note: Efficiency gains/losses is the % change in total surplus relative to initial allocation.)) frac scheme(s1mono)

histogram Effi if SecondH==1, by(treatment, title("Efficiency Gains (losses)") subtitle("Second half") note(Note: Efficiency gains/losses is the % change in total surplus relative to initial allocation.)) scheme(s1mono)

graph box Effi if period>0, by(treatment, title("Efficiency Gains (losses)") subtitle("(All paid periods)") note(Note: Efficiency gains/losses is the % change in total surplus relative to initial allocation.)) scheme(s1mono)
*graph box Effi if period>0, over(SecondH) by(treatment) scheme(s1mono)

tab treat Half, sum(volume)

tab treat Half, sum(Effic)



tab treat Half, sum( price_avg)
tab treat Half, sum( price_last)


sum session
local  N = r(max)
forval n = 1/`N' {
	gen avgP`n'= price_avg if session==`n'
	gen endP`n'= price_last if session==`n'
	gen vol`n' = volume if session==`n'
}
sort period
twoway line avgP1 avgP2 	 avgP4 avgP5 avgP6 avgP7 avgP8 avgP9 avgP10 avgP11 avgP12 avgP13 avgP14 avgP15 avgP16 avgP17 period, by(treatment, legend(off) title(Mean Period Prices) note(Mean transaction prices per period for each session))  yline(100, lwidth(med) lpattern(_) lcolor(gs1)) yline(110, lwidth(med) lpattern(_) lcolor(gs1)) lwidth(medthick medthick medthick medthick medthick medthick medthick medthick medthick medthick medthick medthick medthick ) lcolor(gs12 gs10 gs2 gs10 gs2 gs6 gs8 gs6 gs4 gs8 gs4 gs5 gs5)  scheme(s1mono)

twoway line endP1 endP2 	 endP4 endP5 endP6 endP7 endP8 endP9 endP10 endP11 endP12 endP13 endP14 endP15 endP16 endP17 period, by(treatment, legend(off) title(Closing Prices) note(Last transaction prices per period for each session))  yline(100, lwidth(med) lpattern(_) lcolor(gs1)) yline(110, lwidth(med) lpattern(_) lcolor(gs1)) lwidth(medthick medthick medthick medthick medthick) lcolor(gs10 gs2 gs6 gs8 gs4) 

twoway line vol1  vol2 		 vol4  vol5  vol6  vol7  vol8  vol9  vol10  vol11  vol12  vol13  vol14  vol15  vol16  vol17  period, by(treatment, legend(off) title(trading volume) note(Trading volume per period for each session))  yline(5, lwidth(med) lpattern(_) lcolor(gs0)) lwidth(medthick medthick medthick medthick medthick) lcolor(gs2 gs6 gs10 gs8 gs4) lpattern(l l l) scheme(s1mono)

graph box volume, by(treatment, title(Trading Volume)) yline(5, lwidth(medthick) lpattern(_) lcolor(gs0)) scheme(s1mono)
x 

*************************************
*************************************
*************************************
*****	Analyze Simulations 	*****
*************************************
*************************************
*************************************

*use $path_data\SimPeriodSummary, clear
use SimPeriodSummary, clear

egen NumPeriods = max(period), by(session)
gen SecondHalf = 0
replace SecondHalf=period>(NumPeriods/2)
gen Half=SecondHalf+1 if period>0

lab var sim_treat "MIA"

gen maxvalue = 1450
gen Efficiency_gain = ( endingvalue - beginningvalue)/( maxvalue - beginningvalue)
lab var Efficiency_gain "Efficiency gain (relative to initial allocation)"
lab var Efficiency_gain "Efficiency gain (loss)"


histogram Effi if period>0, by(treatment sim_treat, title("Efficiency Gains (losses)") subtitle("(All simulated periods)") note(Note: Efficiency gains/losses is the % change in total surplus relative to initial allocation.)) frac 


tab treat sim_treat, sum(volume)

tab treat sim_treat, sum(Effic)



tab treat sim_treat, sum( price_avg)
tab treat sim_treat, sum( price_last)




egen mEff=mean(Effic), by( sim_treatment treat)

twoway (scatter Effic totalAction if totalAction<=350, by( sim_treatment treat) msize(vsmall)) (qfit Effic totalAction if totalAction<=350, lwidth(medthick))

twoway (scatter Effic totalAction if totalAction<=350, by( sim_treatment treat,  legend(off) title("Efficiency gain and total bids+asks, by Treatment and Agent type") subtitle(Scatter plot with quadratic fit )) msize(vsmall) mcolor(gs1)) (qfit Effic totalAction if totalAction<=350, lwidth(medium) lpattern(l) lcolor(maroon) scheme(s2mono)  yline(0, lpattern(-)))


twoway (scatter price_avg totalAction if totalAction<=350, by(sim_treatment treat,  legend(off) title("Price and total bids+asks, by Treatment and Agent type") subtitle(Scatter plot with quadratic fit )) msize(vsmall) mcolor(gs1)) (qfit price_avg totalAction if totalAction<=350, lwidth(medium) lpattern(l) lcolor(maroon) scheme(s2mono)  yline(100 110, lpattern(- -)))


tab sim_treatment treatment, sum(Eff)

*twoway (scatter Effic totalAction if totalAction<=350 & sim_treatment==0, by( treat) msize(vsmall)) (qfit Effic totalAction if totalAction<=350 & sim_treatment==0, lwidth(medthick)) (line mEff totalAction if totalAction<=350, lwidth(med) lpattern(dash))
twoway (scatter Effic totalAction if totalAction<=350 & sim_treatment==0, by( treat) msize(vsmall)) (qfit Effic totalAction if totalAction<=350 & sim_treatment==0, lwidth(medthick)) (line mEff totalAction if totalAction<=350  & sim_treatment==0, lwidth(med) lpattern(dash))
twoway (scatter Effic totalAction if totalAction<=350 & sim_treatment==1, by( treat) msize(vsmall)) (qfit Effic totalAction if totalAction<=350 & sim_treatment==1, lwidth(medthick)) (line mEff totalAction if totalAction<=350  & sim_treatment==1, lwidth(med) lpattern(dash))

preserve
collapse (mean) mEff=Effic mPrice=price_avg (semean) seEff=Effic sePrice=price_avg (p5) p5Eff=Effic p5Price=price_avg (p95) p95Eff=Effic p95Price=price_avg, by(time_per treatment sim_treat)

twoway (rarea p5Eff p95Eff time_per, color(gs14) scheme(s2mono) yline(0, lpattern(-))) (scatter mEff time_per, msym(d) msize(med) mcolor(gs1) connect(l) lwidth(vthin) lcolor(gs8) by(sim_treat treat, title("Efficiency gain and period length, by Treatment and Agent type") subtitle(Mean and 90% interval) legend(off)))

restore


gen time2=time^2

gen mia = sim_treat
lab var mia "MIA"

lab var totalAction "Bids+Asks per period"

ge totA2=totalAction^2
lab var totA2 "(B+A per period)^2

tobit Eff mia upda time_period , ll(-1) ul(1)
estimate store Model1 
tobit Eff mia upda time_period time2 , ll(-1) ul(1)
estimate store Model2 

coefplot Model1 Model2, ci xline(0, lwidth(thin)) mlabel scheme(s2mono)

tobit Eff  mia upda totalAction, ll(-1) ul(1)
estimate store Model3
tobit Eff  mia upda totalAction totA2, ll(-1) ul(1)
estimate store Model4

coefplot Model3 Model4, ci xline(0, lwidth(thin)) mlabel scheme(s2mono)

*coefplot Model1 Model2 Model3 Model4, ci xline(0, lwidth(thin)) mlabel scheme(s2mono)

coefplot Model1 Model3, ci xline(0, lwidth(thin)) mlabel scheme(s2mono)


separate time_period, by(treatment)


rename time_period1 time_cda
replace time_cda=0 if cda==0

rename time_period2 time_upda
replace time_upda=0 if time_upda==0

separate time_cda, by(sim_treat)
replace time_cda0=0 if sim_treat!=0
replace time_cda1=0 if sim_treat!=1

separate time_upda, by(sim_treat)
replace time_upda0=0 if sim_treat!=0
replace time_upda1=0 if sim_treat!=1

/*
tobit Eff treat sim_treat time_cda time_upda time_cda1 time_upda1 , ll(-1) ul(1)

coefplot, xline(0) ci
*/


