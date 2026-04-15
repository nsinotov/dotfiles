# ===========================================
# Media Compression Aliases
# ===========================================
# Requires: ghostscript (PDF), ffmpeg (video)

# desc: Compress all PDFs in current directory (ebook quality, in-place)
alias compress-pdf="find ./ -type f -name \"*.pdf\" -exec sh -c 'gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"{}-compressed.pdf\" \"{}\" && mv \"{}-compressed.pdf\" \"{}\"' \;"

# desc: Convert all MOV files to H.264 MP4 and remove originals
alias compress-mov='find . -type f -name "*.mov" -exec sh -c '\''ffmpeg -i "$1" -vcodec libx264 -crf 28 -preset medium -vsync cfr -max_muxing_queue_size 9999 -acodec aac -b:a 128k -y "${1%.mov}.mp4" && rm "$1"'\'' _ {} \;'

# desc: Re-encode all MP4 files with lower bitrate (in-place)
alias compress-mp4='find . -type f -name "*.mp4" -exec sh -c '\''ffmpeg -i "$1" -vcodec libx264 -crf 30 -preset slow -b:v 1M -acodec aac -b:a 128k -strict experimental -y "${1%.mp4}_temp.mp4" && mv "${1%.mp4}_temp.mp4" "$1"'\'' _ {} \;'
