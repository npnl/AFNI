#/bin/csh

if ($#argv <1) then
	echo "usage: mri_convert.csh id######"
	exit 1
	endif

set sub = $1

#convert .mgz files to .nii and move to subject directory

cd /data/Freesurfer_subjects/${sub}_anat/mri/

foreach file (aparc+aseg brain wm T1) 
