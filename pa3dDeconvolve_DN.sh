#!/bin/bash

# Filename: waver3dDeconvolve.sh
# Purpose: Run preprocessing steps; Run waver to produce ideal response
#          function (IRF); Run 3dDeconvolve to obtain parameter estimates
#          and calculate contrasts for PA Recall experiment.
# Created: 6/20/06
# Creator: Tyler Seibert
# Usage: ./waver3dDeconvolve.sh

ver=ms # This version mark is appended to data sets written by this script

for s in mj043009 ng041609 jf042809 sm042709 ec041709 sk041709 am041609 rb041409 es041509 lk041509 aw043009 gg043009 
do

cd /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${s}/AFNIfiles
echo "working in $PWD"


# 3dDeconvolve using waver-generated IRF and Pre-processed data
3dDeconvolve -polort 1 \
    -input ScFrBlVrTs_Run1_${ver}+orig ScFrBlVrTs_Run2_${ver}+orig \
           ScFrBlVrTs_Run3_${ver}+orig ScFrBlVrTs_Run4_${ver}+orig \
    -num_stimts 11 \
    -stim_file 1 AllRuns_Onset_CorInc'[0]' -stim_label 1 "Remember-Cor" \
    -stim_file 2 AllRuns_Onset_CorInc'[1]' -stim_label 2 "Know-Cor" \
    -stim_file 3 AllRuns_Onset_CorInc'[2]' -stim_label 3 "Studied-Inc" \
    -stim_file 4 AllRuns_Onset_CorInc'[3]' -stim_label 4 "Novel-Cor" \
    -stim_file 5 AllRuns_Onset_CorInc'[4]' -stim_label 5 "Novel-Inc" \
    -stim_file 6 AllRuns_motion_${ver}'[0]' -stim_base 6 \
    -stim_file 7 AllRuns_motion_${ver}'[1]' -stim_base 7 \
    -stim_file 8 AllRuns_motion_${ver}'[2]' -stim_base 8 \
    -stim_file 9 AllRuns_motion_${ver}'[3]' -stim_base 9 \
    -stim_file 10 AllRuns_motion_${ver}'[4]' -stim_base 10 \
    -stim_file 11 AllRuns_motion_${ver}'[5]' -stim_base 11 \
    -stim_minlag 1 0 -stim_maxlag 1 9 \
    -stim_minlag 2 0 -stim_maxlag 2 9 \
    -stim_minlag 3 0 -stim_maxlag 3 9 \
    -stim_minlag 4 0 -stim_maxlag 4 9 \
    -stim_minlag 5 0 -stim_maxlag 5 9 \
    -fout -tout -nobout -xjpeg Xmat_${ver} \
    -bucket bucket_DN_${ver} \
    -xrestore bucket_CorInc_ms.xsave \
    -num_glt 1 \
    -gltsym 'SYM: +Remember-Cor +Know-Cor +Studied-Inc +Novel-Cor +Novel-Inc' -glt_label 1 Task_vs_NoTask \
    -censor censor_motion.txt


# Adwarp new BL files and iresp files

adwarp -apar ANAT_rot+tlrc -dpar bucket_DN_${ver}+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/Brewer_${s}/Brewer_${s}_ROI/${s}_bucket_DN_${ver} \
-dxyz 4.0 -thr NN -func Bk

done
