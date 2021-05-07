/* data math;
infile 'C:\Users\e80100\Desktop\MathACT.csv' dlm=',' firstobs=2;
input Sex $ Background $ Score;
run;*/

%web_drop_table(WORK.math);


FILENAME REFFILE '/folders/myfolders/6372/Data Sets 6372/MathACT.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.math;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.math; RUN;


%web_open_table(WORK.math);


/*Calculating a summary stats table and outputing the results in a dataset called "meansout"*/

proc means data=math n mean max min range std fw=8;
	class Sex Background;
	var Score;
	output out=meansout mean=mean std=std;
	title 'Summary of Math ACT Scores';
	run;


*The following chunk of code is some basic code to plot the summary statistics in a convenient profile type plot.;
*This will probably take you some time to understand how sas works to finally get the plot but for those who put in the effort, your understanding of SAS
will be better for it and you will soon figure out you can do a lot of differnt things. For those of you who do not have the time, the alternative is to take the summary statistics
output and move them over to excel and create a plot over there.;

data summarystats;
	set meansout;
	if _TYPE_=0 then delete;
	if _TYPE_=1 then delete;
	if _TYPE_=2 then delete;
	run;


*This data step creates the necessary data set to plot the mean estimates along with the error bars;
/* data plottingdata(keep=Sex Background mean std newvar);                                                                                                      
	set summarystats;
	by Sex Background;
	newvar=mean; output;                                                                                                                                                                                                                                                    
	newvar=mean - std; output;                                                                                                                                                                                                                                                            
	newvar=mean + std; output;                                                                                                                              
	run;  
*/

/*********************** This is the revised data step to calculate the upper and lower error bar values ********/

data plottingdata (drop=std);
	set summarystats;
	by Sex Background;
	lower = mean - std;
	upper = mean + std;
	run;
	
/* This style of attributes is not supported in SAS UE *****
*Plotting options to make graph look somewhat decent;
 title1 'Plot Means with Standard Error Bars from Calculated Data for Groups';  

   symbol1 interpol=hiloctj color=vibg line=1;                                                                                          
   symbol2 interpol=hiloctj color=depk line=1;                                                                                          
                                                                                                                                        
   symbol3 interpol=none color=vibg value=dot height=1.5;                                                                               
   symbol4 interpol=none color=depk value=dot height=1.5;  

   axis1 offset=(2,2) ;                                                                                                       
   axis2 label=("Math ACT") order=(0 to 40 by 10) minor=(n=1); 
*/

/*data has to be sorted on the variable which you are going to put on the x axis*/
proc sort data=plottingdata;
   by background;
   run;

proc print data=plottingdata; run;


/* This does not work in SAS UE (university edition) */
/*proc gplot data=plottingdata;
	plot NewVar*Background=Sex / vaxis=axis2 haxis=axis1;
	*Since the first plot is actually 2 (male female) the corresponding symbol1 and symbol2 options are used which is telling sas to make error bars.  The option is hiloctj;
	plot2 Mean*Background=Sex / vaxis=axis2 noaxis nolegend;
	*This plot uses the final 2 symbols options to plot the mean points;
	run;quit;
	*This is the end of the plotting code;
*/

/*************** Updated Code using SGPLOT that will work in SAS UE (university edition) ********************************************/


/* The SCATTER statement generates the scatter plot with error bars. */                                                                 
/* The SERIES statement draws the line to connect the means.         */  
title "Plot Means with Standard Error Bars from Calculated Data for Groups";
proc sgplot data=plottingdata noautolegend;
	scatter x=background y=mean /	yerrorlower=lower
									yerrorupper=upper
									group=sex
									groupdisplay=overlay;
	series x=background y=mean / 	lineattrs=(pattern=solid) 
									group=sex
									groupdisplay=overlay
									name='s';
	yaxis label='Math ACT';
	keylegend 's' / title='Sex';
	run;
	
                                                                                                                       


/*Running 2way anova analysis*/

proc glm data=math PLOTS=(DIAGNOSTICS RESIDUALS);
class sex background;
model score= background sex background*sex;
lsmeans background / pdiff tdiff adjust=bon;
estimate 'B vs A' background -1 1 0;
estimate 'What do you think?' background -1 0 1;
estimate 'What do you think2?' sex -1 1;

run;



