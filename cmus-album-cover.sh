#!/bin/bash
function rgb_to_term() {
    if [[ ! $1 =~ ^[0-9]+,[0-9]+,[0-9]+$ ]]; then
        return 1
    fi
    IFS=',' read -r r g b <<< "$1"
    if ((r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255)); then
        echo "Error: RGB values must be in the range 0-255" >&2
        return 1
    fi
    r_6=$(( ($r * 6) / 256 ))
    g_6=$(( ($g * 6) / 256 ))
    b_6=$(( ($b * 6) / 256 ))
    ansi_code=$(( 16 + ($r_6 * 36) + ($g_6 * 6) + $b_6 ))
    echo "${ansi_code}"
}
#get complementary color
compl_rgb() {
	IFS=',' read -r R G B <<< ${1}
	R=$(expr 255 - ${R})
	G=$(expr 255 - ${G})
	B=$(expr 255 - ${B})
	echo "${R},${G},${B}"
}
#
# get album cover
PLAYINGSONG="" 
while true
do
	cmus=$(cmus-remote -C status 2>&1)
	if [ "${cmus}" = "" ]; then
		break
	else
#		echo "${PLAYINGSONG},playing"
		CURRENTSONG=$(cmus-remote -C status | grep file | sed 's/file //')
	#	echo "${CURRENTSONG},current"
		if [ "${PLAYINGSONG}" = "${CURRENTSONG}" ]; then
			#	#echo "skip"
			:
		else
			PLAYINGSONG="${CURRENTSONG}"
			ffmpeg -y -i  "${PLAYINGSONG}" -an -vcodec copy /tmp/cover.jpg > /dev/null 2>&1 </dev/null
			RGB=$(magick /tmp/cover.jpg -resize 1x1 txt:- | grep -oP '\(\K[^)]*' | grep -v "%")
			if echo ${RGB} | grep "," ;then
				:
			else
				# gray scale
				RGB=$(echo "${RGB},${RGB},${RGB}")
			fi
			cmus-remote -C "set color_win_title_bg=$(rgb_to_term "${RGB}")"
			#echo $(rgb_to_term "${RGB}")
			#echo "${RGB}"
			cmus-remote -C "set color_titleline_bg=$(rgb_to_term "${RGB}")"
			cmus-remote -C "set color_statusline_bg=$(rgb_to_term "${RGB}")"
		#cmus-remote -C "set color_cmdline_bg=$(rgb_to_term "${RGB}")"#echo "main rgb color ${RGB}"
#		echo "complementary rgb color $(compl_rgb "${RGB}")"
#		echo "main rgb color to term color $(rgb_to_term "${RGB}")"
#		echo "complemantary rgb color to $(rgb_to_term "$(compl_rgb "${RGB}")")"
		# set compl color to fg color
			cmus-remote -C "set color_titleline_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
			cmus-remote -C "set color_win_title_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
			cmus-remote -C "set color_statusline_fg=$(rgb_to_term "$(compl_rgb "${RGB}")")"
			cmus-remote -C "set color_win_cur=$(rgb_to_term "${RGB}")"
		#feh --bg-scale /tmp/cover.jpg
		fi
	fi
done
exit 0
