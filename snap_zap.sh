#!/bin/bash

if [[ -e /tmp/snaps.txt ]]; then
      rm /tmp/snaps.txt
fi

touch /tmp/snaps.txt

LUNS=`df -h| grep emscp | cut -d"/" -f1,2,3 |sort | uniq`

for l in $LUNS; do

snapdrive snap list -filervol $l >> /tmp/snaps.txt


DELS = cat snaps.txt | grep `hostname` | cut -f1 -d" "


done
