#!/bin/bash

# Filename: Correlation.sh
# Purpose: Run to get Z-score for individual subjects with a seed region (for event-related)
# Created: 06/09/08
# Creator: Sarah Israel
# Usage: ./Correlation.sh

ver=fc # This version mark is appended to data sets written by this script

sub=$1

cd /space/mdj1/1/data/sarah/PA_suppress/Brewer_${sub}/AFNIfiles/Correlation_HC


echo "working in $PWD"

efficients for interaction to Z scores through Fisher transformation

#3dDeconvolve can only output coefficient of determination R2, not correlation coefficient R itself. So we need to take square root of R2 and find out its sign based on the sign of its corresponding beta value:

3dcalc -a HC_correlation_${ver}+tlrc'[72]' -b HC_correlation_${ver}+tlrc'[70]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix HC_Corr_${sub}

3dcalc -a HC_correlation_${ver}+tlrc'[76]' -b HC_correlation_${ver}+tlrc'[74]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix HC_Corr_inter_${sub}


#Since correlation coefficients range from -1 to 1. To be able to run group analysis, Fisher's Z transformation formula can be used to reduce skewness and make the sampling distribution more normal when sample size is big enough: z =  (1/2) * ln((1+r)/(1-r)), where z is approximately normally distributed with mean r, and standard error 1/(n-3)0.5 (n: sample size).

3dcalc -a HC_Corr_${sub}+tlrc -expr 'log((1+a)/(1-a))/2' -prefix CorrHC_${sub}_Z
3dcalc -a HC_Corr_inter_${sub}+tlrc -expr 'log((1+a)/(1-a))/2' -prefix CorrHC_${sub}_inter_Z

cp *Z* ../../../Group_CorrHC
