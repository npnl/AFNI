#!/bin/bash

# Filename: Correlation.sh
# Purpose: Run to get Z-score for individual subjects with a seed region (for event-related)
# Created: 06/09/08
# Creator: Sarah Israel
# Usage: ./Correlation.sh

ver=fc # This version mark is appended to data sets written by this script

sub=$1

cd /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/
mkdir Correlation_HC_All
cd Correlation_HC_All


echo "working in $PWD"

#	0. Adwarp ScFrBlVrTs files into Talairach space

adwarp -apar ../ANAT_rot+tlrc \
-dpar ../finalstage_pas/ScFrBlVrTs_Run1_pas+orig \
-prefix /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC_All/ScFrBlVrTs_Run1_pas \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ../ANAT_rot+tlrc \
-dpar ../finalstage_pas/ScFrBlVrTs_Run2_pas+orig \
-prefix /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC_All/ScFrBlVrTs_Run2_pas \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ../ANAT_rot+tlrc \
-dpar ../finalstage_pas/ScFrBlVrTs_Run3_pas+orig \
-prefix /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC_All/ScFrBlVrTs_Run3_pas \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ../ANAT_rot+tlrc \
-dpar ../finalstage_pas/ScFrBlVrTs_Run4_pas+orig \
-prefix /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC_All/ScFrBlVrTs_Run4_pas \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ../ANAT_rot+tlrc \
-dpar ../finalstage_pas/ScFrBlVrTs_Run5_pas+orig \
-prefix /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC_All/ScFrBlVrTs_Run5_pas \
-dxyz 4.0 -thr NN -func Bk

# 	1. For each run extract the average time series of the ROI

#HC
3dmaskave -mask ../../../Analysis_AllCond/R-HC+tlrc ScFrBlVrTs_Run1_pas+tlrc > Seed_HC_R1.1D
3dmaskave -mask ../../../Analysis_AllCond/R-HC+tlrc ScFrBlVrTs_Run2_pas+tlrc > Seed_HC_R2.1D
3dmaskave -mask ../../../Analysis_AllCond/R-HC+tlrc ScFrBlVrTs_Run3_pas+tlrc > Seed_HC_R3.1D
3dmaskave -mask ../../../Analysis_AllCond/R-HC+tlrc ScFrBlVrTs_Run4_pas+tlrc > Seed_HC_R4.1D
3dmaskave -mask ../../../Analysis_AllCond/R-HC+tlrc ScFrBlVrTs_Run5_pas+tlrc > Seed_HC_R5.1D

#	2. Remove the trend from the seed time series

#HC
#3dDetrend -polort 0 -prefix Seed_HC_R1 Seed_HC_Run1.1D
#3dDetrend -polort 0 -prefix Seed_HC_R2 Seed_HC_Run2.1D
#3dDetrend -polort 0 -prefix Seed_HC_R3 Seed_HC_Run3.1D
#3dDetrend -polort 0 -prefix Seed_HC_R4 Seed_HC_Run4.1D
#3dDetrend -polort 0 -prefix Seed_HC_R5 Seed_HC_Run5.1D


#	3. Run deconvolution on the seed time series

#First generate the impulse response function:

waver -dt 1.5 -GAM -inline 1@1 > GammaHR.1D

#Then run:

3dTfitter -RHS Seed_HC_R1.1D -FALTUNG GammaHR.1D Seed_HC_Run1_Neur 012 0.0
3dTfitter -RHS Seed_HC_R2.1D -FALTUNG GammaHR.1D Seed_HC_Run2_Neur 012 0.0
3dTfitter -RHS Seed_HC_R3.1D -FALTUNG GammaHR.1D Seed_HC_Run3_Neur 012 0.0
3dTfitter -RHS Seed_HC_R4.1D -FALTUNG GammaHR.1D Seed_HC_Run4_Neur 012 0.0
3dTfitter -RHS Seed_HC_R5.1D -FALTUNG GammaHR.1D Seed_HC_Run5_Neur 012 0.0

#Plot out Seed_Neur.1D and see if it looks reasonable comparing to the stimulus presentation in the experiment. You may want to experiment with different penality functions (check details of option -FALTUNG in 3dTffitter -help).


#	4. Obtain the interaction regressor

#First create a 1D file, AvsBcoding.1D,  with 0's (at those TR's where neither condition A nor B occurred), 1's (at those TR's where condition A occurred), and -1's (at those TR's where condition B occurred). If you only consider one condition A, there are two options: (1) If the baseline condition more or less matches up with condition A, make it a constrast with condition A (coded with 1's) versus baseline (coded with -1's); (2) If you don't believe that there is modulation (interaction) between the seed and the baseline, code condition with 1's and all other time points with 0's.

# Make Seed_*_Run*_Neur into a column instead of a row

1dtranspose Seed_HC_Run1_Neur.1D Seed_HC_R1_Neur.1D
1dtranspose Seed_HC_Run2_Neur.1D Seed_HC_R2_Neur.1D
1dtranspose Seed_HC_Run3_Neur.1D Seed_HC_R3_Neur.1D
1dtranspose Seed_HC_Run4_Neur.1D Seed_HC_R4_Neur.1D
1dtranspose Seed_HC_Run5_Neur.1D Seed_HC_R5_Neur.1D

1deval -a Seed_HC_R1_Neur.1D -b ../SvsRCcoding.1D'[0]' -expr 'a*b' > Inter_neu_HC_Run1.1D
1deval -a Seed_HC_R2_Neur.1D -b ../SvsRCcoding.1D'[1]' -expr 'a*b' > Inter_neu_HC_Run2.1D
1deval -a Seed_HC_R3_Neur.1D -b ../SvsRCcoding.1D'[2]' -expr 'a*b' > Inter_neu_HC_Run3.1D
1deval -a Seed_HC_R4_Neur.1D -b ../SvsRCcoding.1D'[3]' -expr 'a*b' > Inter_neu_HC_Run4.1D
1deval -a Seed_HC_R5_Neur.1D -b ../SvsRCcoding.1D'[4]' -expr 'a*b' > Inter_neu_HC_Run5.1D

1dtranspose Seed_HC_R1_Neur.1D Seed_HC_Run1_Neur.1D 

#The interaction is created as

waver -GAM -peak 1 -TR 1.5  -input Inter_neu_HC_Run1.1D -numout 278 > Inter_HC_Run1_ts.1D
waver -GAM -peak 1 -TR 1.5  -input Inter_neu_HC_Run2.1D -numout 278 > Inter_HC_Run2_ts.1D
waver -GAM -peak 1 -TR 1.5  -input Inter_neu_HC_Run3.1D -numout 278 > Inter_HC_Run3_ts.1D
waver -GAM -peak 1 -TR 1.5  -input Inter_neu_HC_Run4.1D -numout 278 > Inter_HC_Run4_ts.1D
waver -GAM -peak 1 -TR 1.5  -input Inter_neu_HC_Run5.1D -numout 278 > Inter_HC_Run5_ts.1D


#	5. Concatenate the regressors if there are multilple runs

#Run cat separately on Seed_ts.1D (final output from step(2)) and Inter_ts.1D (final output from step(4)), and use the 2 concatenated 1D files for the next step.

cat Seed_HC_R1.1D Seed_HC_R2.1D Seed_HC_R3.1D Seed_HC_R4.1D Seed_HC_R5.1D > Seed_HC_ts.1D

cat Inter_HC_Run1_ts.1D Inter_HC_Run2_ts.1D Inter_HC_Run3_ts.1D Inter_HC_Run4_ts.1D Inter_HC_Run5_ts.1D > Inter_HC_ts.1D

#	6. Regression analysis

3dDeconvolve -polort 1 \
    -input ScFrBlVrTs_Run1_pas+tlrc ScFrBlVrTs_Run2_pas+tlrc \
           ScFrBlVrTs_Run3_pas+tlrc ScFrBlVrTs_Run4_pas+tlrc \
	   ScFrBlVrTs_Run5_pas+tlrc \
    -num_stimts 14 \
    -stim_file 1 ../AllRuns_Onset.txt'[0]' -stim_label 1 "Red" \
    -stim_file 2 ../AllRuns_Onset.txt'[1]' -stim_label 2 "Blue" \
    -stim_file 3 ../AllRuns_Onset.txt'[2]' -stim_label 3 "Green" \
    -stim_file 4 ../AllRuns_Onset.txt'[3]' -stim_label 4 "Red-Inc" \
    -stim_file 5 ../AllRuns_Onset.txt'[4]' -stim_label 5 "Blue-Inc" \
    -stim_file 6 ../AllRuns_Onset.txt'[5]' -stim_label 6 "Green-Inc" \
    -stim_file 7 ../AllRuns_motion_pas'[0]' -stim_base 7 \
    -stim_file 8 ../AllRuns_motion_pas'[1]' -stim_base 8 \
    -stim_file 9 ../AllRuns_motion_pas'[2]' -stim_base 9 \
    -stim_file 10 ../AllRuns_motion_pas'[3]' -stim_base 10 \
    -stim_file 11 ../AllRuns_motion_pas'[4]' -stim_base 11 \
    -stim_file 12 ../AllRuns_motion_pas'[5]' -stim_base 12 \
    -stim_file 13 Seed_HC_ts.1D -stim_base 13 \
    -stim_file 14 Inter_HC_ts.1D -stim_base 14 \
    -rout -fout -tout -bout \
    -bucket HC_correlation_${ver} \
    -xsave \
    -GOFORIT 15 \
    -censor ../censor_motion.txt


#	7. Convert the correction coefficients for interaction to Z scores through Fisher transformation

#3dDeconvolve can only output coefficient of determination R2, not correlation coefficient R itself. So we need to take square root of R2 and find out its sign based on the sign of its corresponding beta value:

3dcalc -a HC_correlation_${ver}+tlrc'[72]' -b HC_correlation_${ver}+tlrc'[70]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix HC_Corr_${sub}

3dcalc -a HC_correlation_${ver}+tlrc'[76]' -b HC_correlation_${ver}+tlrc'[74]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix HC_Corr_inter_${sub}


#Since correlation coefficients range from -1 to 1. To be able to run group analysis, Fisher's Z transformation formula can be used to reduce skewness and make the sampling distribution more normal when sample size is big enough: z =  (1/2) * ln((1+r)/(1-r)), where z is approximately normally distributed with mean r, and standard error 1/(n-3)0.5 (n: sample size).

3dcalc -a HC_Corr_${sub}+tlrc -expr 'log((1+a)/(1-a))/2' -prefix CorrHC_${sub}_Z
3dcalc -a HC_Corr_inter_${sub}+tlrc -expr 'log((1+a)/(1-a))/2' -prefix CorrHC_${sub}_inter_Z

cp *Z* ../../../Group_CorrHC_All
