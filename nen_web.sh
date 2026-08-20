#!/bin/bash
set -e
cd "$(dirname "$0")"
until grep -q "✅ Xong" build.log 2>/dev/null; do sleep 10; done
echo "▶ Bản gốc: $(du -h video.mp4 | cut -f1)"
mv video.mp4 video-goc.mp4
BR=980
ffmpeg -y -loglevel error -i video-goc.mp4 -c:v libx264 -preset slow -b:v ${BR}k -pass 1 -an -f null /dev/null
ffmpeg -y -loglevel error -i video-goc.mp4 -c:v libx264 -preset slow -b:v ${BR}k -pass 2 \
  -c:a aac -b:a 128k -movflags +faststart video.mp4
rm -f ffmpeg2pass-*.log*
echo "✅ Bản web: $(du -h video.mp4 | cut -f1)  |  gốc giữ ở video-goc.mp4 ($(du -h video-goc.mp4 | cut -f1))"
