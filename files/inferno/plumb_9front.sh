mkdir /mnt/9front
mount -A tcp!192.168.1.136!5555 /mnt/9front
mkdir /tmp/chan/
touch /tmp/chan/plumb.input
bind /mnt/9front/mnt/plumb/send /tmp/chan/plumb.input
unmount /chan
bind /tmp/chan /chan
plumb $1

