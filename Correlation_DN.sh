#!/bin/bash

# Filename: Correlation_DN.sh
# Purpose: Run to get Z-score for individual subjects with a seed region in HC (for event-related)
# Created: 03/20/08
# Creator: Sarah Israel
# Usage: ./Correlation_032008.sh

ver=fc # This version mark is appended to data sets written by this script

sub=$1

cd Brewer_${sub}/AFNIfiles/
mkdir Correlation
cd Correlation

echo "working in $PWD"

rm Seed* Inter* Corr* Sc*

#______________
# 1) For each run, extract the average time series of the ROI

adwarp -apar ../ANAT_rot+tlrc -dpar ../ScFrBlVrTs_Run1_ms+orig -dxyz 4 -prefix /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${sub}/AFNIfiles/Correlation/ScFrBlVrTs_Run1_ms
adwarp -apar ../ANAT_rot+tlrc -dpar ../ScFrBlVrTs_Run2_ms+orig -dxyz 4 -prefix /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${sub}/AFNIfiles/Correlation/ScFrBlVrTs_Run2_ms
adwarp -apar ../ANAT_rot+tlrc -dpar ../ScFrBlVrTs_Run3_ms+orig -dxyz 4 -prefix /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${sub}/AFNIfiles/Correlation/ScFrBlVrTs_Run3_ms
adwarp -apar ../ANAT_rot+tlrc -dpar ../ScFrBlVrTs_Run4_ms+orig -dxyz 4 -prefix /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${sub}/AFNIfiles/Correlation/ScFrBlVrTs_Run4_ms

3dmaskave -mask ../../../Analysis_8subj/Clustorder_ttest.05_PR-CN_HC+tlrc ScFrBlVrTs_Run1_paf_sc+tlrc > Seed_Run1.1D
3dmaskave -mask ../../../Analysis_8subj/Clustorder_ttest.05_PR-CN_HC+tlrc ScFrBlVrTs_Run2_paf_sc+tlrc > Seed_Run2.1D
3dmaskave -mask ../../../Analysis_8subj/Clustorder_ttest.05_PR-CN_HC+tlrc ScFrBlVrTs_Run3_paf_sc+tlrc > Seed_Run3.1D
3dmaskave -mask ../../../Analysis_8subj/Clustorder_ttest.05_PR-CN_HC+tlrc ScFrBlVrTs_Run4_paf_sc+tlrc > Seed_Run4.1D

#______________
# 2) Remove the trend from the seed time series then make into one-column time series

#3dDetrend -polort 0 -prefix SeedRun1.1D Seed_Run1.1D'[0]'
#3dDetrend -polort 0 -prefix SeedRun2.1D Seed_Run2.1D'[0]'
#3dDetrend -polort 0 -prefix SeedRun3.1D Seed_Run3.1D'[0]'
#3dDetrend -polort 0 -prefix SeedRun4.1D Seed_Run4.1D'[0]'

1dcat Seed_Run1.1D'[0]' > Seed_1.1D
1dcat Seed_Run2.1D'[0]' > Seed_2.1D
1dcat Seed_Run3.1D'[0]' > Seed_3.1D
1dcat Seed_Run4.1D'[0]' > Seed_4.1D

#______________
# 3) Run deconvolution on the seed time series

waver -dt 1.5 -GAM -inline 1@1 > GammaHR.1D

3dTfitter -RHS Seed_1.1D -FALTUNG GammaHR.1D Seed_Neur1 012 0.0
3dTfitter -RHS Seed_2.1D -FALTUNG GammaHR.1D Seed_Neur2 012 0.0
3dTfitter -RHS Seed_3.1D -FALTUNG GammaHR.1D Seed_Neur3 012 0.0
3dTfitter -RHS Seed_4.1D -FALTUNG GammaHR.1D Seed_Neur4 012 0.0

#______________
# 4) Obtain the interaction regressor

1dtranspose Seed_Neur1.1D Seed_N1.1D
1dtranspose Seed_Neur2.1D Seed_N2.1D
1dtranspose Seed_Neur3.1D Seed_N3.1D
1dtranspose Seed_Neur4.1D Seed_N4.1D

1deval -a Seed_N1.1D -b ../../../RvsKcoding.1D'[0]' -expr 'a*b' > Inter_Neur1.1D
1deval -a Seed_N2.1D -b ../../../RvsKcoding.1D'[1]' -expr 'a*b' > Inter_Neur2.1D
1deval -a Seed_N3.1D -b ../../../RvsKcoding.1D'[2]' -expr 'a*b' > Inter_Neur3.1D
1deval -a Seed_N4.1D -b ../../../RvsKcoding.1D'[3]' -expr 'a*b' > Inter_Neur4.1D

#______________
# 5) Concatenate the regressors for multiple runs

cat Seed_1.1D Seed_2.1D Seed_3.1D Seed_4.1D > Seed_ts.1D

cat Inter_Neur1.1D Inter_Neur2.1D Inter_Neur3.1D Inter_Neur4.1D > Inter_ts.1D

#______________
# 6) Regression analysis

3dDeconvolve \
    -polort 0 \
    -input ScFrBlVrTs_Run1_ms+tlrc \
           ScFrBlVrTs_Run2_ms+tlrc \
           ScFrBlVrTs_Run3_ms+tlrc \
           ScFrBlVrTs_Run4_ms+tlrc \
    -num_stimts 8 \
    -stim_file 1 Seed_ts.1D -stim_label 1 "CorrelationWithSeed" \
    -stim_file 2 Inter_ts.1D -stim_label 2 "Interaction" \
    -stim_file 3 ../AllRuns_motion_ms'[0]' -stim_base 3 \
    -stim_file 4 ../AllRuns_motion_ms'[1]' -stim_base 4 \
    -stim_file 5 ../AllRuns_motion_ms'[2]' -stim_base 5 \
    -stim_file 6 ../AllRuns_motion_ms'[3]' -stim_base 6 \
    -stim_file 7 ../AllRuns_motion_ms'[4]' -stim_base 7 \
    -stim_file 8 ../AllRuns_motion_ms'[5]' -stim_base 8 \
    -tout -rout \
    -bucket Corr_${sub}

#______________
# 7) Convert the correction coefficients for interaction to Z-scores through Fisher transformation

3dcalc -a Corr_${sub}+tlrc'[4]' -b Corr_${sub}+tlrc'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix Corr_${sub}_CorWithSeed_R
3dcalc -a Corr_${sub}+tlrc'[7]' -b Corr_${sub}+tlrc'[5]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix Corr_${sub}_Inter_R

3dcalc -a Corr_${sub}_CorWithSeed_R+tlrc -expr 'log((1+a)/(1-a))/2' -prefix Corr_${sub}_CorWithSeed_Z
3dcalc -a Corr_${sub}_Inter_R+tlrc -expr 'log((1+a)/(1-a))/2' -prefix Corr_${sub}_Inter_Z

cp *Z+tlrc* ../../../Analysis_new
