#!/bin/sh
# Start EXWM window manager

# Set background
if [ -f /usr/share/backgrounds/archlinux/simple-dark.xml ]; then
    feh --bg-scale /usr/share/backgrounds/archlinux/simple-dark.xml &
else
    xsetroot -solid "#2E3440" &
fi

# Start compositor
picom --experimental-backends --daemon &

# Set keyboard layout (adjust as needed)
setxkbmap us &

# Start NetworkManager applet if available
if command -v nm-applet &> /dev/null; then
    nm-applet &
fi

# Start Emacs/EXWM
exec emacs
