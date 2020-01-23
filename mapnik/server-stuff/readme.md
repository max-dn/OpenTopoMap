Some scripts and configs from the opentopomap server. Most of them
will not work on any other machine.

The opentopomap server has two Intel Xeon CPU E5-2630, 64GByte RAM, 1 SSD
drive with 1 TByte for the database (without indices and tablespace-slim-data) 
and hdds for the rest of the data.

## Files:

### scripts/crontab
Part of the crontab

### config/postgresql.conf, config/tirex.conf
Configs for database and Tirex

### scripts/cleancache  
Removes the oldest files in Z16-Z17, if the tile cache gets too full

### scripts/diffupdate.sh
Does a differential backup (with or without lowzoom update) or only
a lowzoom update. This part runs as root, because it needs to stop 
tirex and change the web site.

### scripts/update_daily_db.sh
Does the main part of differential update, startet as database user. 

### script/tirexbatch
Starts the backround rendering.

### scripts/tirexwatch
Write logs about cache usage and memory usage, restarts tirex, if it stucks.

