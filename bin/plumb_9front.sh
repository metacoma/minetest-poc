#!/bin/sh

path=`echo $1 | sed 's,^/9gridchan,,'`

docker run --rm --network mine9wm_minetest-poc -v /home/bebebeko/mine9wm/files/inferno/:/usr/inferno/host --entrypoint /bin/sh -ti metacoma/inferno-os -c "emu /dis/sh /host/plumb_9front.sh $path"
