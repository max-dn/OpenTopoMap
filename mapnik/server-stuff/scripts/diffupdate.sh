#!/bin/bash
#
# do daily update
# start/stop tirex if its a update with -withlowzoom          (that means all lowzoom tables will be rebuilt)
#                                       -stoptirex            (tirex is stopped, but no lowzoom update)
#                                       -onlypreprocessinging (stop tirex, do all preprocessing, but no import of recent changes)
#

# rotate logs
#

lin=`cat /home/otmuser/logs/update.log 2>/dev/null | wc -l`
if [ $lin -gt 10000 ] ; then
 mv /home/otmuser/logs/update.log /home/otmuser/logs/update.log.1
 touch /home/otmuser/logs/update.log
 chown otmuser /home/otmuser/logs/update.log
fi

tirexstatus=`ps axf | grep -v grep | grep tirex-master  | wc -l`


d=`date +"%Y-%m-%d %H:%M:%S"`
echo "$d --root-------------------------------------------------------------------" >> /home/otmuser/logs/update.log

#
# stop tirex if lowzoom will be updated, at least kill the background rendering
#

dbspace=`df -h | grep /mnt/database | awk '{gsub("%","");print $5;}'` ; echo $dbspace

if [ $dbspace -lt 95 ] ; then 
 if [ "$1" = "-withlowzoom" -o  "$1" = "-stoptirex" -o "$1" = "-onlypreprocessing" ] ; then
  d=`date +"%Y-%m-%d %H:%M:%S"`
  echo "$d stopping tirex because option $1 is set"  >> /home/otmuser/logs/update.log
  /etc/init.d/tirex-backend-manager stop
  /etc/init.d/tirex-master stop
 else
  d=`date +"%Y-%m-%d %H:%M:%S"`
  echo "$d stopping tirex-batch, emty tirex queue"  >> /home/otmuser/logs/update.log
  /etc/init.d/tirex-backend-manager restart
  /etc/init.d/tirex-master restart
  killall tirex-batch
  sleep 30
  tirex-send stop_rendering_bucket "bucket=background"
 fi

#
# start update (as user otmuser)
#
 
 echo "$d starting update as otmuser"  >> /home/otmuser/logs/update.log
 su - otmuser -c "/home/otmuser/OpenTopoMap/mapnik/tools/update_daily_db.sh $1 $2 $3 >>/home/otmuser/logs/update.log 2>>/home/otmuser/logs/update.log" 
 d=`date +"%Y-%m-%d %H:%M:%S"`
 
#
# start tirex and batch renderer, if it was running before
#
 
 d=`date +"%Y-%m-%d %H:%M:%S"`
 if [ $tirexstatus -gt 0 ] ; then 
  if [ "$1" = "-withlowzoom" -o  "$1" = "-stoptirex" -o "$1" = "-onlypreprocessing" ] ; then
   echo "$d starting tirex"  >> /home/otmuser/logs/update.log
   /etc/init.d/tirex-backend-manager start
   /etc/init.d/tirex-master start
  else
   echo "$d restarting tirex"  >> /home/otmuser/logs/update.log
   /etc/init.d/tirex-backend-manager restart
   /etc/init.d/tirex-master restart
  fi
  sleep 30
  tirex-send continue_rendering_bucket "bucket=background"
  su - tirex -c "nohup /usr/local/bin/tirexbatch >/dev/null 2>/dev/null &"
 fi
 if [ -e /home/otmuser/data/updates/latest_lowzoom ] ; then 
  latest_lowzoom=`cat /home/otmuser/data/updates/latest_lowzoom`
  d=`date -u +"%d.%m.%Y" --date $latest_lowzoom`
  infostring="<p>Stand der Datenbank: $d. Teile der Karte k\&ouml;nnen auch maximal 4 Wochen \&auml;lter sein.<\/p>"
  sed "s/<!-- IMPORTDATE -->.*/<!-- IMPORTDATE -->$infostring/" <  /var/www/html/about > /tmp/updateabout
  l=`cat /tmp/updateabout | wc -l`
  if [ $l -gt 100 ] ;then 
   d=`date +"%Y-%m-%d %H:%M:%S"`
   echo "$d updating https://opentopomap.org/about"  >> /home/otmuser/logs/update.log
   cp /var/www/html/about /var/www/html/about.bak
   cat /tmp/updateabout >  /var/www/html/about
   rm /tmp/updateabout
  fi
 fi
 d=`date +"%Y-%m-%d %H:%M:%S"`
 echo "$d database size"  >> /home/otmuser/logs/update.log
 du -sh /mnt/database/*      >> /home/otmuser/logs/update.log
 du -sh /mnt/tiles/database/ >> /home/otmuser/logs/update.log
 if [ "$1" = "-withlowzoom" -o "$1" = "-onlypreprocessing" ] ; then
  d=`date +"%Y-%m-%d %H:%M:%S"`
  echo "$d starting expire_tiles, logs in expire_tiles.log"  >> /home/otmuser/logs/update.log
  /usr/local/bin/expire_tiles 12 15 17 > /home/otmuser/logs/expire_tiles.log 2> /home/otmuser/logs/expire_tiles.err
  tail -3 /home/otmuser/logs/expire_tiles.log >> /home/otmuser/logs/update.log
 fi
 d=`date +"%Y-%m-%d %H:%M:%S"`
 echo "$d --/root------------------------------------------------------------------" >> /home/otmuser/logs/update.log
else
 d=`date +"%Y-%m-%d %H:%M:%S"`
 echo "$d doing nothing, because no space in file system: $dbspace %"                >> /home/otmuser/logs/update.log
 echo "$d --/root------------------------------------------------------------------" >> /home/otmuser/logs/update.log
fi
 
 