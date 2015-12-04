#!/bin/bash

# Filename: waver3dDeconvolve.sh
# Purpose: Run preprocessing steps; Run waver to produce ideal response
#          function (IRF); Run 3dDeconvolve to obtain parameter estimates
#          and calculate contrasts for PA Recall experiment.
# Created: 6/20/06
# Creator: Tyler Seibert
# Usage: ./waver3dDeconvolve.sh

ver=ms # This version mark is appended to data sets written by this script

selectSubdir()
{
    echo "Which subject do you want to analyze?"
    echo "Please enter the name of the subject's directory"
    select subdir in Brewer_*; do
	if [ $subdir ]; then
	    break
	else
	    echo 'invalid selection'
	fi
    done
}

fs4

cd /space/mdj1/1/data/sarah/Memory_Strength
echo "pwd is $PWD"
selectSubdir
cd $subdir/AFNIfiles
echo "working in $PWD"

# For each Run
for num in 1 2 3 4; do

    # Timeshift to 0
    3dTshift -tzero 0 \
	-prefix Ts_Run${num}_${ver} \
	Run${num}.nii.gz 

done

for num in 1 2 3 4; do
    # Register to midpoint of Run 2
    3dvolreg -base Ts_Run2_${ver}+orig'[173]' \
	-prefix VrTs_Run${num}_${ver} \
	-1Dfile motion_${num} \
	Ts_Run${num}_${ver}+orig

    # Blur (smooth) by FWHM 4 mm
    3dmerge -1blur_fwhm 4 \
	-doall \
	-prefix BlVrTs_Run${num}_${ver} \
	VrTs_Run${num}_${ver}+orig

 # Remove highpass and lowpass 
    3dFourier -prefix FrBlVrTs_Run${num}_${ver} -lowpass .1 -highpass .01 -ignore 5 -retrend BlVrTs_Run${num}_${ver}+orig

    # Create brain-only mask for Run
    3dAutomask -dilate 1 \
	-prefix mask_Run${num}_${ver} \
	FrBlVrTs_Run${num}_${ver}+orig

done

# Combine Run masks to get full mask
3dcalc -a mask_Run1_${ver}+orig -b mask_Run2_${ver}+orig -c mask_Run3_${ver}+orig \
    -d mask_Run4_${ver}+orig \
    -expr 'or(a+b+c+d)' \
    -prefix full_mask_${ver}

# Scale each Run's mean to 100
for num in 1 2 3 4; do
    3dTstat -prefix mean_Run${num}_${ver} \
	FrBlVrTs_Run${num}_${ver}+orig
    3dcalc -a BlVrTs_Run${num}_${ver}+orig \
	-b mean_Run${num}_${ver}+orig \
	-c full_mask_${ver}+orig \
	-expr "(a/b * 100) * c" \
	-prefix ScFrBlVrTs_Run${num}_${ver}
    rm -f mean_Run${num}_${ver}+orig*
done

# Call motion_censor.pl

    perl ../../move_censor.pl
    echo "Wrote censor_motion.txt"

# Concatenate motion files
cat motion_1 motion_2 motion_3 motion_4 > AllRuns_motion_${ver}

# Move temporary files to separate directory
mkdir stages_${ver}
mv Ts_Run?_${ver}* VrTs_Run?_${ver}* BlVrTs_Run?_${ver}* FrBlVrTs_Run?_${ver}* \
    Run?_${ver}_motion* \
    mask_Run?_${ver}* stages_${ver}
mv VrTs_outliers_*_${ver}.txt outliers


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
    -iresp 1 "Remember-Cor_iresp" \
    -iresp 2 "Know-Cor_iresp" \
    -iresp 3 "Studied-Inc_iresp" \
    -iresp 4 "Novel-Cor_iresp" \
    -iresp 5 "Novel-Inc_iresp" \
    -fout -tout -nobout -xjpeg Xmat_${ver} \
    -bucket bucket_CorInc_${ver} \
    -xsave \
    -num_glt 8 \
    -gltsym 'SYM: +Remember-Cor' -glt_label 1 Remember-Cor \
    -gltsym 'SYM: +Know-Cor' -glt_label 2 Know-Cor \
    -gltsym 'SYM: +Studied-Inc' -glt_label 3 Studied-Inc \
    -gltsym 'SYM: +Novel-Cor' -glt_label 4 Novel-Cor \
    -gltsym 'SYM: +Novel-Inc' -glt_label 5 Novel-Inc \
    -gltsym 'SYM: +Remember-Cor -Know-Cor' -glt_label 6 Rem-Know \
    -gltsym 'SYM: +Remember-Cor +Know-Cor -Studied-Inc' -glt_label 7 Studied_Cor-Inc \
    -gltsym 'SYM: +Novel-Cor -Novel-Inc' -glt_label 8 Novel_Cor-Inc \
    -censor censor_motion.txt

3dDeconvolve -polort 1 \
    -input ScFrBlVrTs_Run1_${ver}+orig ScFrBlVrTs_Run2_${ver}+orig \
           ScFrBlVrTs_Run3_${ver}+orig ScFrBlVrTs_Run4_${ver}+orig \
    -num_stimts 21 \
    -stim_file 1 AllRuns_Onset_RT'[0]' -stim_label 1 "R+" \
    -stim_file 2 AllRuns_Onset_RT'[1]' -stim_label 2 "R" \
    -stim_file 3 AllRuns_Onset_RT'[2]' -stim_label 3 "R-" \
    -stim_file 4 AllRuns_Onset_RT'[3]' -stim_label 4 "K+" \
    -stim_file 5 AllRuns_Onset_RT'[4]' -stim_label 5 "K" \
    -stim_file 6 AllRuns_Onset_RT'[5]' -stim_label 6 "K-" \
    -stim_file 7 AllRuns_Onset_RT'[6]' -stim_label 7 "I+" \
    -stim_file 8 AllRuns_Onset_RT'[7]' -stim_label 8 "I" \
    -stim_file 9 AllRuns_Onset_RT'[8]' -stim_label 9 "I-" \
    -stim_file 10 AllRuns_Onset_RT'[9]' -stim_label 10 "NC+" \
    -stim_file 11 AllRuns_Onset_RT'[10]' -stim_label 11 "NC" \
    -stim_file 12 AllRuns_Onset_RT'[11]' -stim_label 12 "NC-" \
    -stim_file 13 AllRuns_Onset_RT'[12]' -stim_label 13 "NI+" \
    -stim_file 14 AllRuns_Onset_RT'[13]' -stim_label 14 "NI" \
    -stim_file 15 AllRuns_Onset_RT'[14]' -stim_label 15 "NI-" \
    -stim_file 16 AllRuns_motion_${ver}'[0]' -stim_base 16 \
    -stim_file 17 AllRuns_motion_${ver}'[1]' -stim_base 17 \
    -stim_file 18 AllRuns_motion_${ver}'[2]' -stim_base 18 \
    -stim_file 19 AllRuns_motion_${ver}'[3]' -stim_base 19 \
    -stim_file 20 AllRuns_motion_${ver}'[4]' -stim_base 20 \
    -stim_file 21 AllRuns_motion_${ver}'[5]' -stim_base 21 \
    -stim_minlag 1 0 -stim_maxlag 1 9 \
    -stim_minlag 2 0 -stim_maxlag 2 9 \
    -stim_minlag 3 0 -stim_maxlag 3 9 \
    -stim_minlag 4 0 -stim_maxlag 4 9 \
    -stim_minlag 5 0 -stim_maxlag 5 9 \
    -stim_minlag 6 0 -stim_maxlag 6 9 \
    -stim_minlag 7 0 -stim_maxlag 7 9 \
    -stim_minlag 8 0 -stim_maxlag 8 9 \
    -stim_minlag 9 0 -stim_maxlag 9 9 \
    -stim_minlag 10 0 -stim_maxlag 10 9 \
    -stim_minlag 11 0 -stim_maxlag 11 9 \
    -stim_minlag 12 0 -stim_maxlag 12 9 \
    -stim_minlag 13 0 -stim_maxlag 13 9 \
    -stim_minlag 14 0 -stim_maxlag 14 9 \
    -stim_minlag 15 0 -stim_maxlag 15 9 \
    -iresp 1 "R+_iresp" \
    -iresp 2 "R_iresp" \
    -iresp 3 "R-_iresp" \
    -iresp 4 "K+_iresp" \
    -iresp 5 "K_iresp" \
    -iresp 6 "K-_iresp" \
    -iresp 7 "I+_iresp" \
    -iresp 8 "I_iresp" \
    -iresp 9 "I-_iresp" \
    -iresp 10 "NC+_iresp" \
    -iresp 11 "NC_iresp" \
    -iresp 12 "NC-_iresp" \
    -iresp 13 "NI+_iresp" \
    -iresp 14 "NI_iresp" \
    -iresp 15 "NI-_iresp" \
    -fout -tout -nobout -xjpeg Xmat_${ver} \
    -bucket bucket_RT_${ver} \
    -xsave \
    -goforit 15 \
    -num_glt 21 \
    -gltsym 'SYM: +R+ -R-' -glt_label 1 R+-R- \
    -gltsym 'SYM: +K+ -K-' -glt_label 2 K+-K- \
    -gltsym 'SYM: +I+ -I-' -glt_label 3 I+-I- \
    -gltsym 'SYM: +NC+ -NC-' -glt_label 4 NC+-NC- \
    -gltsym 'SYM: +NI+ -NI-' -glt_label 5 NI+-NI- \
    -gltsym 'SYM: +R+ +K+ +I+ +NC+ +NI+ -R- -K- -I- -NC- -NI-' -glt_label 6 +/- \
    -gltsym 'SYM: +R+' -glt_label 7 R+ \
    -gltsym 'SYM: +R' -glt_label 8 R \
    -gltsym 'SYM: +R-' -glt_label 9 R- \
    -gltsym 'SYM: +K+' -glt_label 10 K+ \
    -gltsym 'SYM: +K' -glt_label 11 K \
    -gltsym 'SYM: +K-' -glt_label 12 K- \
    -gltsym 'SYM: +I+' -glt_label 13 I+ \
    -gltsym 'SYM: +I' -glt_label 14 I \
    -gltsym 'SYM: +I-' -glt_label 15 I- \
    -gltsym 'SYM: +NC+' -glt_label 16 NC+ \
    -gltsym 'SYM: +NC' -glt_label 17 NC \
    -gltsym 'SYM: +NC-' -glt_label 18 NC- \
    -gltsym 'SYM: +NI+' -glt_label 19 NI+ \
    -gltsym 'SYM: +NI' -glt_label 20 NI \
    -gltsym 'SYM: +NI-' -glt_label 21 NI- \
    -censor censor_motion.txt

#.5RT
3dDeconvolve -polort 1 \
    -input ScFrBlVrTs_Run1_${ver}+orig ScFrBlVrTs_Run2_${ver}+orig \
           ScFrBlVrTs_Run3_${ver}+orig ScFrBlVrTs_Run4_${ver}+orig \
    -num_stimts 21 \
    -stim_file 1 AllRuns_Onset_.5RT'[0]' -stim_label 1 "R+" \
    -stim_file 2 AllRuns_Onset_.5RT'[1]' -stim_label 2 "R" \
    -stim_file 3 AllRuns_Onset_.5RT'[2]' -stim_label 3 "R-" \
    -stim_file 4 AllRuns_Onset_.5RT'[3]' -stim_label 4 "K+" \
    -stim_file 5 AllRuns_Onset_.5RT'[4]' -stim_label 5 "K" \
    -stim_file 6 AllRuns_Onset_.5RT'[5]' -stim_label 6 "K-" \
    -stim_file 7 AllRuns_Onset_.5RT'[6]' -stim_label 7 "I+" \
    -stim_file 8 AllRuns_Onset_.5RT'[7]' -stim_label 8 "I" \
    -stim_file 9 AllRuns_Onset_.5RT'[8]' -stim_label 9 "I-" \
    -stim_file 10 AllRuns_Onset_.5RT'[9]' -stim_label 10 "NC+" \
    -stim_file 11 AllRuns_Onset_.5RT'[10]' -stim_label 11 "NC" \
    -stim_file 12 AllRuns_Onset_.5RT'[11]' -stim_label 12 "NC-" \
    -stim_file 13 AllRuns_Onset_.5RT'[12]' -stim_label 13 "NI+" \
    -stim_file 14 AllRuns_Onset_.5RT'[13]' -stim_label 14 "NI" \
    -stim_file 15 AllRuns_Onset_.5RT'[14]' -stim_label 15 "NI-" \
    -stim_file 16 AllRuns_motion_${ver}'[0]' -stim_base 16 \
    -stim_file 17 AllRuns_motion_${ver}'[1]' -stim_base 17 \
    -stim_file 18 AllRuns_motion_${ver}'[2]' -stim_base 18 \
    -stim_file 19 AllRuns_motion_${ver}'[3]' -stim_base 19 \
    -stim_file 20 AllRuns_motion_${ver}'[4]' -stim_base 20 \
    -stim_file 21 AllRuns_motion_${ver}'[5]' -stim_base 21 \
    -stim_minlag 1 0 -stim_maxlag 1 9 \
    -stim_minlag 2 0 -stim_maxlag 2 9 \
    -stim_minlag 3 0 -stim_maxlag 3 9 \
    -stim_minlag 4 0 -stim_maxlag 4 9 \
    -stim_minlag 5 0 -stim_maxlag 5 9 \
    -stim_minlag 6 0 -stim_maxlag 6 9 \
    -stim_minlag 7 0 -stim_maxlag 7 9 \
    -stim_minlag 8 0 -stim_maxlag 8 9 \
    -stim_minlag 9 0 -stim_maxlag 9 9 \
    -stim_minlag 10 0 -stim_maxlag 10 9 \
    -stim_minlag 11 0 -stim_maxlag 11 9 \
    -stim_minlag 12 0 -stim_maxlag 12 9 \
    -stim_minlag 13 0 -stim_maxlag 13 9 \
    -stim_minlag 14 0 -stim_maxlag 14 9 \
    -stim_minlag 15 0 -stim_maxlag 15 9 \
    -iresp 1 "R+_.5_iresp" \
    -iresp 2 "R_.5_iresp" \
    -iresp 3 "R-_.5_iresp" \
    -iresp 4 "K+_.5_iresp" \
    -iresp 5 "K_.5_iresp" \
    -iresp 6 "K-_.5_iresp" \
    -iresp 7 "I+_.5_iresp" \
    -iresp 8 "I_.5_iresp" \
    -iresp 9 "I-_.5_iresp" \
    -iresp 10 "NC+_.5_iresp" \
    -iresp 11 "NC_.5_iresp" \
    -iresp 12 "NC-_.5_iresp" \
    -iresp 13 "NI+_.5_iresp" \
    -iresp 14 "NI_.5_iresp" \
    -iresp 15 "NI-_.5_iresp" \
    -fout -tout -nobout -xjpeg Xmat_${ver} \
    -bucket bucket_.5RT_${ver} \
    -xsave \
    -goforit 15 \
    -num_glt 21 \
    -gltsym 'SYM: +R+ -R-' -glt_label 1 R+-R- \
    -gltsym 'SYM: +K+ -K-' -glt_label 2 K+-K- \
    -gltsym 'SYM: +I+ -I-' -glt_label 3 I+-I- \
    -gltsym 'SYM: +NC+ -NC-' -glt_label 4 NC+-NC- \
    -gltsym 'SYM: +NI+ -NI-' -glt_label 5 NI+-NI- \
    -gltsym 'SYM: +R+ +K+ +I+ +NC+ +NI+ -R- -K- -I- -NC- -NI-' -glt_label 6 +/- \
    -gltsym 'SYM: +R+' -glt_label 7 R+ \
    -gltsym 'SYM: +R' -glt_label 8 R \
    -gltsym 'SYM: +R-' -glt_label 9 R- \
    -gltsym 'SYM: +K+' -glt_label 10 K+ \
    -gltsym 'SYM: +K' -glt_label 11 K \
    -gltsym 'SYM: +K-' -glt_label 12 K- \
    -gltsym 'SYM: +I+' -glt_label 13 I+ \
    -gltsym 'SYM: +I' -glt_label 14 I \
    -gltsym 'SYM: +I-' -glt_label 15 I- \
    -gltsym 'SYM: +NC+' -glt_label 16 NC+ \
    -gltsym 'SYM: +NC' -glt_label 17 NC \
    -gltsym 'SYM: +NC-' -glt_label 18 NC- \
    -gltsym 'SYM: +NI+' -glt_label 19 NI+ \
    -gltsym 'SYM: +NI' -glt_label 20 NI \
    -gltsym 'SYM: +NI-' -glt_label 21 NI- \
    -censor censor_motion.txt


#mean
3dDeconvolve -polort 1 \
    -input ScFrBlVrTs_Run1_${ver}+orig ScFrBlVrTs_Run2_${ver}+orig \
           ScFrBlVrTs_Run3_${ver}+orig ScFrBlVrTs_Run4_${ver}+orig \
    -num_stimts 16 \
    -stim_file 1 AllRuns_Onset_meanRT'[0]' -stim_label 1 "R+" \
    -stim_file 2 AllRuns_Onset_meanRT'[1]' -stim_label 2 "R-" \
    -stim_file 3 AllRuns_Onset_meanRT'[2]' -stim_label 3 "K+" \
    -stim_file 4 AllRuns_Onset_meanRT'[3]' -stim_label 4 "K-" \
    -stim_file 5 AllRuns_Onset_meanRT'[4]' -stim_label 5 "I+" \
    -stim_file 6 AllRuns_Onset_meanRT'[5]' -stim_label 6 "I-" \
    -stim_file 7 AllRuns_Onset_meanRT'[6]' -stim_label 7 "NC+" \
    -stim_file 8 AllRuns_Onset_meanRT'[7]' -stim_label 8 "NC-" \
    -stim_file 9 AllRuns_Onset_meanRT'[8]' -stim_label 9 "NI+" \
    -stim_file 10 AllRuns_Onset_meanRT'[9]' -stim_label 10 "NI-" \
    -stim_file 11 AllRuns_motion_${ver}'[0]' -stim_base 11 \
    -stim_file 12 AllRuns_motion_${ver}'[1]' -stim_base 12 \
    -stim_file 13 AllRuns_motion_${ver}'[2]' -stim_base 13 \
    -stim_file 14 AllRuns_motion_${ver}'[3]' -stim_base 14 \
    -stim_file 15 AllRuns_motion_${ver}'[4]' -stim_base 15 \
    -stim_file 16 AllRuns_motion_${ver}'[5]' -stim_base 16 \
    -stim_minlag 1 0 -stim_maxlag 1 9 \
    -stim_minlag 2 0 -stim_maxlag 2 9 \
    -stim_minlag 3 0 -stim_maxlag 3 9 \
    -stim_minlag 4 0 -stim_maxlag 4 9 \
    -stim_minlag 5 0 -stim_maxlag 5 9 \
    -stim_minlag 6 0 -stim_maxlag 6 9 \
    -stim_minlag 7 0 -stim_maxlag 7 9 \
    -stim_minlag 8 0 -stim_maxlag 8 9 \
    -stim_minlag 9 0 -stim_maxlag 9 9 \
    -stim_minlag 10 0 -stim_maxlag 10 9 \
    -iresp 1 "R+_mean_iresp" \
    -iresp 3 "R-_mean_iresp" \
    -iresp 4 "K+_mean_iresp" \
    -iresp 6 "K-_mean_iresp" \
    -iresp 7 "I+_mean_iresp" \
    -iresp 9 "I-_mean_iresp" \
    -iresp 10 "NC+_mean_iresp" \
    -iresp 12 "NC-_mean_iresp" \
    -iresp 13 "NI+_mean_iresp" \
    -iresp 15 "NI-_mean_iresp" \
    -fout -tout -nobout -xjpeg Xmat_${ver} \
    -bucket bucket_meanRT_${ver} \
    -xsave \
    -goforit 15 \
    -num_glt 16 \
    -gltsym 'SYM: +R+ -R-' -glt_label 1 R+-R- \
    -gltsym 'SYM: +K+ -K-' -glt_label 2 K+-K- \
    -gltsym 'SYM: +I+ -I-' -glt_label 3 I+-I- \
    -gltsym 'SYM: +NC+ -NC-' -glt_label 4 NC+-NC- \
    -gltsym 'SYM: +NI+ -NI-' -glt_label 5 NI+-NI- \
    -gltsym 'SYM: +R+ +K+ +I+ +NC+ +NI+ -R- -K- -I- -NC- -NI-' -glt_label 6 +/- \
    -gltsym 'SYM: +R+' -glt_label 7 R+ \
    -gltsym 'SYM: +R-' -glt_label 8 R- \
    -gltsym 'SYM: +K+' -glt_label 9 K+ \
    -gltsym 'SYM: +K-' -glt_label 10 K- \
    -gltsym 'SYM: +I+' -glt_label 11 I+ \
    -gltsym 'SYM: +I-' -glt_label 12 I- \
    -gltsym 'SYM: +NC+' -glt_label 13 NC+ \
    -gltsym 'SYM: +NC-' -glt_label 14 NC- \
    -gltsym 'SYM: +NI+' -glt_label 15 NI+ \
    -gltsym 'SYM: +NI-' -glt_label 16 NI- \
    -censor censor_motion.txt

# Move data sets and masks to separate directory
mkdir finalstage_${ver}
mv ScFrBlVrTs_Run?_${ver}* full_mask_${ver}* Xmat_${ver}* finalstage_${ver}

# Adwarp new BL files and iresp files

adwarp -apar ANAT_rot+tlrc -dpar bucket_CorInc_${ver}+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_bucket_CorInc_${ver} \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar bucket_RT_${ver}+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_bucket_RT_${ver} \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar bucket_.5RT_${ver}+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_bucket_.5RT_${ver} \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar bucket_meanRT_${ver}+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_bucket_meanRT_${ver} \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar Remember-Cor_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_Remember-Cor_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar Know-Cor_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_Know-Cor_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar Studied-Inc_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_Studied-Inc_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar Novel-Cor_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_Novel-Cor_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar Novel-Inc_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_Novel-Inc_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R+_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R+_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R-_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R-_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K+_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K+_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K-_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K-_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I+_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I+_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I-_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I-_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC+_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC+_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC-_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC-_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI+_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI+_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI-_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI-_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R+_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R+_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R-_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R-_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K+_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K+_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K-_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K-_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I+_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I+_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I-_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I-_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC+_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC+_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC-_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC-_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI+_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI+_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI_.5_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI-_.5_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI-_.5_iresp \
-dxyz 4.0 -thr NN -func Bk


adwarp -apar ANAT_rot+tlrc -dpar R+_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R+_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar R-_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_R-_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K+_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K+_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar K-_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_K-_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I+_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I+_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar I-_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_I-_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC+_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC+_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NC-_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NC-_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI+_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI+_mean_iresp \
-dxyz 4.0 -thr NN -func Bk

adwarp -apar ANAT_rot+tlrc -dpar NI-_mean_iresp+orig \
-prefix /space/mdj1/1/data/sarah/Memory_Strength/${subdir}/${subdir}_ROI/${subdir}_NI-_mean_iresp \
-dxyz 4.0 -thr NN -func Bk


