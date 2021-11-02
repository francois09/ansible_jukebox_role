#!/bin/bash
unclutter -idle 0.5 -root &
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/francois/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/francois/.config/chromium/Default/Preferences
/usr/bin/chromium --noerrdialogs --disable-infobars --kiosk http://127.0.0.1:6680/iris &
{% if jukebox__autoplay_random|default(False) %}
# Put some files for first playback

# 1 - Extract track list into temp file
TRACKS_FILE=$(mktemp tkXXXXXXX.tracks)
curl -s -d '{"jsonrpc": "2.0", "id": 1, "method": "core.library.browse", "params" : {"uri": "local:directory?type=track" }}' \
     -H 'Content-Type: application/json' http://localhost:6680/mopidy/rpc \
    | jq '.result'|grep '"uri":' | sed -e 's/.*"uri": "//;s/",//' > $TRACKS_FILE
# 2 - Compute the tracks number
TRACKS_NUMBER=$(wc -l $TRACKS_FILE|sed -e 's/ .*//')

# 3 - Create a random list
TRACKS=""
for n in $(seq 1 40)
do
    TRACKS="${TRACKS}$(( $RANDOM * $TRACKS_NUMBER / 32768 + 1))p;"
done

# 4 - Add tracks to tracklist
URIS="["$(sed -n "$TRACKS" $TRACKS_FILE|\
while read TRK
do
  echo "\""${TRK}"\","
done)"]"

URIS=$(echo $URIS|sed -e 's/,\]/\]/')
D='{"jsonrpc": "2.0", "id": 1, "method": "core.tracklist.add", "params" : {"uris": '${URIS}' }}'
curl -s -d "$D" -H 'Content-Type: application/json' http://localhost:6680/mopidy/rpc > /dev/null

# 5 - Set consume mode
curl -s -d '{"jsonrpc": "2.0", "id": 1, "method": "core.tracklist.set_consume", "params" : {"value" : true }}' -H 'Content-Type: application/json' http://localhost:6680/mopidy/rpc > /dev/null

# 6 - Set volume to middle
curl -s -d '{"jsonrpc": "2.0", "id": 1, "method": "core.mixer.set_volume", "params" : {"volume" : 50 }}' -H 'Content-Type: application/json' http://localhost:6680/mopidy/rpc > /dev/null

# 7 - Play !
curl -s -d '{"jsonrpc": "2.0", "id": 1, "method": "core.playback.play"}' -H 'Content-Type: application/json' http://localhost:6680/mopidy/rpc > /dev/null

# 8 - Remove temp file
rm -f $TRACKS_FILE
{% endif %}
