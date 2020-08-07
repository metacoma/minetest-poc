unmount /chan
mkdir -p /mnt/inferno
mount -A tcp!192.168.1.253!3333 /mnt/inferno
bind /mnt/inferno/chan /chan
plumb $1

