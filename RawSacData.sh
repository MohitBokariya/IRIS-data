#!/bin/sh
# Mohit Bokariya
#email : mohit.seismology@gmail.com

#For Downloading SAC Data From IRIS of Any Network and Station publicaly available 

net=XF      	#Network name
stn=H1540          #Station name		
cmp=LHZ             #Component/Channel Name
lcode=02       #Location
startdate=2004-06-01
enddate=2005-12-31

#Directory-
#Here data will download
Dir="/media/iiser/Shaktimaan/Download/${net}/${stn}"

#Here data we move after instrument correction.
dir="/media/iiser/Shaktimaan/Data/${net}/${stn}"

#If diroctory does'nt exist it will create
[ ! -d "$Dir" ] && mkdir -p "$Dir" 
[ ! -d "$dir" ] && mkdir -p "$dir" 

cd $Dir
#Command for data download 

FetchData -S ${stn} -C ${cmp} -s ${startdate}T00:00:00 -e ${enddate}T01:00:00 -o ${stn}.mseed -rd .


#Creating Date sequence file from start date to end date

curr="$startdate"
while true; do
    echo "$curr"
    [ "$curr" \< "$enddate" ] || break
    curr=$( date +%Y-%m-%d --date "$curr +1 day" )
done > dateseq.sq		#All date (Start to end) are stored in dateseq.sq file

for idate in `cat dateseq.sq`
do
  cd $Dir	
  rm -f ${stn}.mseed ${stn}.metadata *SAC
  nxdate=`date +%Y-%m-%d --date "$idate +1 day"`
  
  FetchData -N ${net} -S ${stn} -C ${cmp} -L ${lcode} -s ${idate}T00:00:00 -e ${nxdate}T00:00:00 -o ${stn}.mseed -m ${stn}.metadata
  
  
  if [ -f ${Dir}/${stn}.mseed ]
  then
     mseed2sac ${stn}.mseed -m ${stn}.metadata
     
     #Converting Date in Julian day
     ijdate=`echo $idate | tr "-" "/"`
     jday=`date -d "$idate" +%j`
     sjday=`date -d "$idate" +%j | bc`
     iyr=`date -d "$idate" +%Y`
     
     
     ##checking if sac file is more that one for a day . If it is more than one then delete it
     sacnum=`ls -1 *${iyr}*${sjday}*SAC | wc -l`
     if [ ${sacnum} -gt 1 ]
     then
        rm -f *SAC
     else
        sacnm=`ls -1 *SAC`
        echo $sacnm
        nzjday=`saclst nzjday f $sacnm | awk '{printf "%03d",$2}'`
        echo ${iyr}.${nzjday} >> ${net}.${stn}.${cmp}.Dates.txt     #rename sac file 
        
#Remove maen, remove trend, tapering and Instrument correction using sac  
#if you don't have installed SAC then comment this section      
sac << eof
r $sacnm
rtr 
rmean
taper
trans from evalresp to none freq 0.001 0.002 0.25 0.5
w over
q
eof

#moving sac data and renaming in "Network.Station.Component.Year.JulianDay.SAC" format
        
        mv $sacnm $dir/${net}.${stn}.${cmp}.${iyr}.${nzjday}.SAC
        
     fi
     
     rm ${stn}.mseed ${stn}.metadata
     	
  fi
  
done

