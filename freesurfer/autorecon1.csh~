#/bin/csh

set sub = $1

cd /data/jenad/FreeSurfer_subjects/
mksubjdirs ${sub}_anat
cp /data/jenad/fMRI/Brewer_${sub}/AFNIfiles/afni_key/ANAT_rot+orig* /data/jenad/FreeSurfer_subjects/${sub}_anat/mri/orig
cd /data/jenad/FreeSurfer_subjects/${sub}_anat/mri/orig
mri_convert ${sub}_anat+orig.BRIK 001.mgz

recon-all -autorecon1 -s ${sub}_anat

tkmedit ${sub}_anat brainmask.mgz -aux T1.mgz

echo "autorecon1 has completed.  Please check skullstripping with tkmedit"

exit
