#!/bin/bash
# get album cover 
PLAYINGSONG=$(cmus-remote -C status | grep file | sed 's/file //')
ffmpeg -y -i  "${PLAYINGSONG}" -an -vcodec copy /tmp/cover.jpg > /dev/null 2>&1 </dev/null
# get rgb to ansi color
function rgb_to_term() {
    if [[ ! $1 =~ ^[0-9]+,[0-9]+,[0-9]+$ ]]; then
        echo "Usage: rgb_to_term \"R,G,B\" (each 0-255)" >&2
        return 1
    fi
    IFS=',' read -r r g b <<< "$1"
    if ((r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255)); then
        echo "Error: RGB values must be in the range 0-255" >&2
        return 1
    fi
    [[ $r -lt 75 ]] && r=0
    [[ $g -lt 75 ]] && g=0
    [[ $b -lt 75 ]] && b=0
    echo $(( ((r-35)/40)*6*6 + ((g-35)/40)*6 + ((b-35)/40) + 16 ))
}
# get main color from album art
RGB=$(magick /tmp/cover.jpg -resize 1x1 txt:- | grep -oP '\(\K[^)]*' | grep -v "%")
# set album main color
cmus-remote -C "set color_win_title_bg=$(rgb_to_term "${RGB}")"
cmus-remote -C "set color_titleline_bg=$(rgb_to_term "${RGB}")"
cmus-remote -C "set color_statusline_bg=$(rgb_to_term "${RGB}")"
#cmus-remote -C "set color_cmdline_bg=$(rgb_to_term "${RGB}")"
#get complementary color
compl_rgb() {
	IFS=',' read -r R G B <<< ${1}
	R=$(expr 255 - ${R})
	G=$(expr 255 - ${G})
	B=$(expr 255 - ${B})
	echo "${R},${G},${B}"
}
echo "main rgb color ${RGB}"
echo "complementary rgb color $(compl_rgb "${RGB}")"
echo "main rgb color to term color $(rgb_to_term "${RGB}")"
echo "complemantary rgb color to $(rgb_to_term "$(compl_rgb "${RGB}")")"
# set compl color to fg color
cmus-remote -C "set color_titleline_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
cmus-remote -C "set color_win_title_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
cmus-remote -C "set color_statusline_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
cmus-remote -C "set color_win_cur=$(rgb_to_term "${RGB}")"
