# ===========================================
# Media Compression Aliases
# ===========================================
# Module: media (installs ghostscript and ffmpeg)
# module: media
# section: Media

[[ " ${DOTFILES_MODULES:-} " == *" media "* ]] || return 0

# desc: Compress every PDF under the current directory, in place
# detail: Recursive. Ghostscript /ebook quality (~150 dpi images); originals are
# detail: overwritten, so run it on a copy if you need them. Requires ghostscript.
# example: cd ~/Documents/scans && compress-pdf
alias compress-pdf="find ./ -type f -name \"*.pdf\" -exec sh -c 'gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"{}-compressed.pdf\" \"{}\" && mv \"{}-compressed.pdf\" \"{}\"' \;"

# desc: Convert every MOV under the current directory to H.264 MP4
# detail: Recursive. CRF 28, AAC 128k audio; each .mov is DELETED after a
# detail: successful conversion. Requires ffmpeg.
# example: cd ~/Movies/screen-recordings && compress-mov
alias compress-mov='find . -type f -name "*.mov" -exec sh -c '\''ffmpeg -i "$1" -vcodec libx264 -crf 28 -preset medium -fps_mode cfr -max_muxing_queue_size 9999 -acodec aac -b:a 128k -y "${1%.mov}.mp4" && rm "$1"'\'' _ {} \;'

# desc: Re-encode every MP4 under the current directory at a lower bitrate
# detail: Recursive. CRF 30 capped at 1 Mbit/s, AAC 128k audio; files are
# detail: replaced in place. Requires ffmpeg.
# example: cd ~/Movies/exports && compress-mp4
alias compress-mp4='find . -type f -name "*.mp4" -exec sh -c '\''ffmpeg -i "$1" -vcodec libx264 -crf 30 -preset slow -b:v 1M -acodec aac -b:a 128k -strict experimental -y "${1%.mp4}_temp.mp4" && mv "${1%.mp4}_temp.mp4" "$1"'\'' _ {} \;'
