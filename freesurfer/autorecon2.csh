#/bin/csh

set sub = $1

nohup recon-all -autorecon2 -autorecon3 -s ${sub}_anat

ROI.csh ${sub}

exit
