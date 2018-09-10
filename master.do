capture log close

clear
clear matrix
set more off

/* ReTrade2 Project (Market Institutions and Re-Trade) */
/* Experiment on ReTrade in Markets, with no pre-defined roles (role discovery) */
*********   MASTER DO-File   **********
/* by Diego Aycinena */
/* Created: 2017-05-23 */
/* located in $my_path\VOI\Do */
/* Last modified: 2018-09-10 */

*set memory 500M		// If necessary
*set matsize 5000		// If necessary
*set maxvar 10000		// If necessary

capture cd "$my_path\ReTrade\ReTrade2\do"		// Set path of working directory

macro drop _all

/* Experimental sessions involved consists of 4 tasks: */
/* 	1) Interactive instructions: read-aloud */
/* 	2) Instruction comprehension quiz: 7 questions that must be answered correctly to proceed (5 of the seven questions are the same for both institutional treatments) */
/*  3) 2 tiral periods: unpaid practice periods  */
/*  4) 15 trading periods: 3 of the 15 periods selected at random at the end to determine final earnings from experiment */
/*  5) Post-Experimental survey: ESI_Psych Survey2 DAA (CRT, hypothetical risk, hypothetical loss aversion and self-reported demographics */


*****************************************
* Description of do-files and programs *
*****************************************
/* Run prepReTrade.do  to Generates Global macros and set up filepaths and folders to be used in this project 
Run numbered programs following their number.
Un-numbered do-files can be ran in whatever order after numbered programs have been ran.
*/

		**************  PREPARATION, READING DATA & CLEAN-UP  *****************
qui: do "$path_do\prepReTrade.do" /*  File paths and macros with file names to read data */
/*	prepReTrade.do
	*****************
	Summary:	Generates Global macros, folders and sets up filepaths and folders to be used in this project.
	Inputs:		--
	Output:		Global file paths and global arrays of file dates (names) to be used to read the data. 
*/


qui: do "$path_do\crReTrade0.do"  
/*	crReTrade0.do
	*****************
	Summary:	Generates Stata files with main datasets for (aggregate) subject level and period level data from the individual data files (Summary_Data_date-time experimental results files and the s#_date_time_ESI ESI Psych Survey generated files)
	Note:		Input files used in these do file have personally ***identifiable information***			 
	Inputs:		Summary_Data_`FileDate'.csv, where 'FileDate' is a global array (FileDate of global file_date_list) defined in prepReTrade, that contains the dates of all the experimental sessions used as names for the experimental file
				quest_file_list_ESI.csv, where 'quest_file_list' is a global array (FileDate of global file_date_list) defined in prepReTrade, that contains the dates of all the sessions used as names for the questionnaire data
	Output:		SocioDemo.dta, Summary0.dta, PeriodSummary00.dta
*/

qui: do "$path_do\crReTrade1.do"  
/*	crReTrade1.do
	*****************
	Summary:	Generates Stata files with main datasets for individual action level (bids, asks, trades, etc.) data from the individual data files (Action_Data_date-time experimental results files). 
				Action data file contains records for all individual and market actions (bids actions, asks actions, trades, etc.) in a session
	Inputs:		Action_Data_`FileDate'.csv, where 'FileDate' is a global array (FileDate of global file_date_list) defined in prepReTrade, that contains the dates of all the experimental sessions used as names for the experimental file
	Output:		Action0.dta
*/

qui: do "$path_do\crReTrade2.do"  
/*	crReTrade2.do
	*****************
	Summary:	creates PeriodSummary0.dta  -- Check Market quantities and prices and fix price for UPDA in PeriodSummary data
	Inputs:		Summary0.dta, PeriodSummary00.dta, Action0.dta
	Output:		PeriodSummary0.dta
*/

qui: do "$path_do\crReTrade3.do"  
/*	crReTrade3.do
	*****************
	Summary:	reads parameter files data to create Params0.dta file, then merges this file with Summary0.dta and PeriodSummary0.dta and Action0.dta to create Summary.dta, PeriodSummary.dta and Action.dta	
	Inputs:		Summary0.dta, PeriodSummary00.dta, Action0.dta
	Output:		Parameters_Data_`FileDate'.csv, where 'FileDate' is a global array (FileDate of global file_date_list) defined in prepReTrade, that contains the dates of all the experimental sessions used as names for the experimental files
				Summary.dta, PeriodSummary.dta, and Action.dta
*/

	/// Simmulations ///
qui: do "$path_do\crReTradeSim0.do" 
/*	crReTradeSim0.do
	*****************
	Summary:	Generates Stata files with master simmulation datasets for (aggregate) subject level and period level data from the individual from the individual Summary_Data_date-time simmulation ("experimental tests") results files
	Inputs:		Summary_Data_`FileDate'.csv, where 'FileDate' are global arrays (FileDate of global zia_f_date_list and nzia_f_date_list) defined in prepReTrade separately for each type of agent simmulation (zero-intelligenece and minimal intelligence), that contains the dates of all the "experimental" sessions used as names for the files
				
	Output:		SimSummary0.dta and SimPeriodSummary00.dta
*/

qui: do "$path_do\crReTradeSim1.do" 
/*	crReTradeSim1.do
	*****************
	Summary:	Generates Stata files with main simulation dataset for individual (robot) action level (bids, asks, trades, etc.) data from the individual data files (Action_Data_date-time experimental results files). 
	Inputs:		Action_Data_`FileDate'.csv, where 'FileDate' are a global arrays (FileDate of global zia_f_date_list and nzia_f_date_list) defined in prepReTrade separately for each type of agent simmulation (zero-intelligenece and minimal intelligence), that contains the dates of all the experimental sessions used as names for the experimental file
	Output:		SimAction0.dta
*/

qui: do "$path_do\crReTradeSim2.do" 
/*	crReTradeSim2.do
	*****************
	Summary:	Check Market quantities and prices and fix price for UPDA in PeriodSummary data -- creates PeriodSummary0.dta
	Inputs:		SimSummary0.dta, SimPeriodSummary00.dta, SimAction0.dta
	Output:		SimPeriodSummary0.dta
*/

qui: do "$path_do\crReTradeSim3.do"  
/*	crReTradeSim3.do
	*****************
	Summary:	reads parameter files data to create SimParams0.dta file, it then merges this file with SimSummary0.dta and SimPeriodSummary0.dta and SimAction0.dta to create SimSummary.dta and SimPeriodSummary.dta and SimAction.dta	
	Inputs:		SimSummary0.dta, SimPeriodSummary00.dta, SimAction0.dta
	Output:		SimSummary.dta, SimPeriodSummary.dta and SimAction.dta
*/

	**************  DATA ANALYSIS  *****************
qui: do "$path_do\



do crVOI-R.do /* creates VOI-Risk.dta -- using z-Tree subjects and globals tables (for ztree treatment 2 (Risk task, ignores other three tasks) as inputs -with Ztree2Stata command  */

do crVOI-In.do /* creates VOI-IndNeglect.dta -- using z-Tree subjects and globals tables (for ztree treatment 3, Independence neglect task) as inputs -with Ztree2Stata command */

do crVOI-BRn.do /* creates VOI-BaseRneglect.dta -- using z-Tree subjects and globals tables (for ztree treatment 4, Base-rate neglect task) as inputs -with Ztree2Stata command */

do crVOI-Full.do /* creates VOI-Full.dta -- merges VOI.dta, VOI-Risk.dta, VOI-IndNeglect.dta, and VOI-BaseRneglect.dta */

***********			***********			***********			***********			***********			***********			***********			***********		
			*******				*******				*******				*******				*******				*******				*******				
***********			***********			***********			***********			***********			***********			***********			***********			



/*   The End   */
