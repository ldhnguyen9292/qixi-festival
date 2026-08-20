#!/bin/bash
# ============================================================
#  Dựng video slideshow từ ảnh + nhạc  (dọc 9:16, Ken Burns + mờ dần)
#  Chạy hoàn toàn trên máy, ảnh/nhạc không đi đâu hết.
#
#     ./make_video.sh            -> dựng video.mp4
#     ./make_video.sh --cards    -> xem trước 3 khung chữ (ra file PNG)
# ============================================================
set -e
cd "$(dirname "$0")"

# ---------------- CHỈNH NỘI DUNG Ở ĐÂY ----------------
T_NAME="BONNIE"
T_SUB="ADVENTURE TOUR"
T_FOOT1="Phim tài liệu 1 tập"
T_FOOT2="Hội đồng Ẩm thực Cần Giờ sản xuất"

E1="Học kì mới rồi,"
E2="em hãy tập một số"
E3="thói quen tốt đi,"
E4="ví dụ như là"
E5="TẬP THÍCH ANH."

PS1="PS:"
PS2="Anh nhận ra mình thích em"
PS3="từ lúc nào đó trong"
PS4="những chuyến đi này."
PS5="♥"

AVATAR="my-avatar.JPG"   # ảnh đại diện tròn ở khung PS cuối (để trống "" là tắt)
AV_SIZE=300              # đường kính ảnh đại diện
SRC="images"        # thư mục chứa ảnh
MUSIC_START=0       # bắt đầu nhạc từ giây thứ mấy
SHOW_DATE=1         # 1 = hiện ngày chụp dưới mỗi ảnh, 0 = tắt
FIT=94              # ảnh chiếm bao nhiêu % khung (nền đen viền quanh, không cắt ảnh)
PHOTO_DUR=3.6       # mỗi ảnh mấy giây
XF=0.8              # chuyển cảnh thường (mờ dần)
XF_LAST=0.45        # cú "lật trang" sang khung PS
XF_LAST_TYPE="slideleft"   # đổi được: slideup / wipeleft / fadewhite / circleopen / pixelize / squeezeh
TITLE_DUR=4.5       # khung mở đầu
END_DUR=8.0         # khung "tập thích anh"
PS_DUR=9.0          # khung PS riêng
W=1080; H=1920; FPS=30
# ------------------------------------------------------

FB="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FU="/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
PINK="0xFF3D86"; INK="0x4A1330"; MUTED="0xA86B8A"; CREAM="0xFFF2F7"
TMP=".build"; rm -rf "$TMP"; mkdir -p "$TMP"

BG="gradients=s=${W}x${H}:c0=0xFFF2F7:c1=0xFFC7DF:x0=0:y0=0:x1=${W}:y1=${H}:speed=0"
BG2="gradients=s=${W}x${H}:c0=0xFF5C9B:c1=0xFF2E7E:x0=0:y0=0:x1=${W}:y1=${H}:speed=0"   # trang PS: hồng đậm cho bất ngờ
STATIC=0; [ "$1" = "--cards" ] && STATIC=1

txt(){ printf '%s' "$2" > "$TMP/$1.txt"; }
dt(){ # 1=file 2=size 3=màu 4=y 5=font 6=lúc hiện ra
  local a=""
  [ "$STATIC" = "0" ] && a=":alpha='if(lt(t,$6),0,min((t-$6)/0.6,1))'"
  echo "drawtext=fontfile='$5':textfile='$TMP/$1.txt':fontsize=$2:fontcolor=$3:x=(w-text_w)/2:y=$4$a"
}
dtq(){ # như dt nhưng hiện nhanh (0.3s) — dùng cho trang PS
  local a=""
  [ "$STATIC" = "0" ] && a=":alpha='if(lt(t,$6),0,min((t-$6)/0.3,1))'"
  echo "drawtext=fontfile='$5':textfile='$TMP/$1.txt':fontsize=$2:fontcolor=$3:x=(w-text_w)/2:y=$4$a"
}

txt n "$T_NAME"; txt s "$T_SUB"; txt f1 "$T_FOOT1"; txt f2 "$T_FOOT2"
txt e1 "$E1"; txt e2 "$E2"; txt e3 "$E3"; txt e4 "$E4"; txt e5 "$E5"
txt p1 "$PS1"; txt p2 "$PS2"; txt p3 "$PS3"; txt p4 "$PS4"; txt p5 "$PS5"

TITLE_F="$(dt n 150 $PINK 700 "$FB" 0.2),$(dt s 66 $INK 900 "$FB" 0.9),$(dt f1 34 $MUTED 1040 "$FU" 1.6),$(dt f2 34 $MUTED 1092 "$FU" 1.6)"
END_F="$(dt e1 58 $INK 620 "$FU" 0.3),$(dt e2 58 $INK 725 "$FU" 1.2),$(dt e3 58 $INK 810 "$FU" 1.2),$(dt e4 58 $INK 925 "$FU" 2.4),$(dt e5 84 $PINK 1025 "$FB" 3.4)"
if [ -n "$AVATAR" ] && [ -f "$AVATAR" ]; then
  PS_F="$(dtq p1 58 $CREAM 850 "$FB" 0.5),$(dtq p2 62 $CREAM 950 "$FB" 0.75),$(dtq p3 62 $CREAM 1035 "$FB" 1.05),$(dtq p4 62 $CREAM 1120 "$FB" 1.35),$(dtq p5 100 $CREAM 1250 "$FU" 2.3)"
else
  PS_F="$(dtq p1 58 $CREAM 700 "$FB" 0.5),$(dtq p2 62 $CREAM 800 "$FB" 0.75),$(dtq p3 62 $CREAM 885 "$FB" 1.05),$(dtq p4 62 $CREAM 970 "$FB" 1.35),$(dtq p5 100 $CREAM 1100 "$FU" 2.3)"
fi

# ---- cắt ảnh đại diện thành hình tròn + viền trắng ----
AV_PNG=""
if [ -n "$AVATAR" ] && [ -f "$AVATAR" ]; then
  R=$((AV_SIZE/2)); RING=$((AV_SIZE+16)); RR=$((RING/2))
  ffmpeg -y -loglevel error -i "$AVATAR" \
    -vf "scale=${AV_SIZE}:${AV_SIZE}:force_original_aspect_ratio=increase,crop=${AV_SIZE}:${AV_SIZE},format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lte(hypot(X-$R,Y-$R),$R),255,0)'" \
    -frames:v 1 "$TMP/av_circle.png"
  ffmpeg -y -loglevel error -f lavfi -i "color=c=white:s=${RING}x${RING}" \
    -vf "format=rgba,geq=r=255:g=255:b=255:a='if(lte(hypot(X-$RR,Y-$RR),$RR),255,0)'" \
    -frames:v 1 "$TMP/av_ring.png"
  ffmpeg -y -loglevel error -i "$TMP/av_ring.png" -i "$TMP/av_circle.png" \
    -filter_complex "[0][1]overlay=8:8" -frames:v 1 "$TMP/avatar.png"
  AV_PNG="$TMP/avatar.png"
  echo "▶ Ảnh đại diện: $AVATAR"
fi

if [ "$STATIC" = "1" ]; then
  ffmpeg -y -loglevel error -f lavfi -i "$BG"  -frames:v 1 -vf "$TITLE_F" "$TMP/preview_1_title.png"
  ffmpeg -y -loglevel error -f lavfi -i "$BG"  -frames:v 1 -vf "$END_F"   "$TMP/preview_2_end.png"
  if [ -n "$AV_PNG" ]; then
    ffmpeg -y -loglevel error -f lavfi -i "$BG2" -i "$AV_PNG" \
      -filter_complex "[0:v]$PS_F[bg];[bg][1:v]overlay=(W-w)/2:460" -frames:v 1 "$TMP/preview_3_ps.png"
  else
    ffmpeg -y -loglevel error -f lavfi -i "$BG2" -frames:v 1 -vf "$PS_F" "$TMP/preview_3_ps.png"
  fi
  echo "✅ Xem trước 3 khung trong $TMP/"
  exit 0
fi

# ---------------- gom ảnh, sắp theo NGÀY CHỤP ----------------
[ -d "$SRC" ] || SRC="photos"
[ -d "$SRC" ] || { echo "❌ Không thấy thư mục ảnh ($SRC)."; exit 1; }

for f in "$SRC"/*.[Hh][Ee][Ii][Cc]; do
  [ -e "$f" ] || continue
  sips -s format jpeg "$f" --out "${f%.*}.jpg" >/dev/null 2>&1 && rm "$f" && echo "đổi HEIC -> JPG: $f"
done

python3 - "$SRC" > "$TMP/order.tsv" <<'PYEOF'
import os, sys, subprocess, datetime
d = sys.argv[1]; rows = []
for f in sorted(os.listdir(d)):
    if not f.lower().endswith(('.jpg', '.jpeg', '.png')): continue
    p = os.path.join(d, f); ts = None
    out = subprocess.run(['sips', '-g', 'creation', p], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if 'creation:' in line:
            v = line.split('creation:')[1].strip()
            if v and v != '<nil>':
                try: ts = datetime.datetime.strptime(v, '%Y:%m:%d %H:%M:%S')
                except ValueError: pass
    if ts is None: ts = datetime.datetime.fromtimestamp(os.path.getmtime(p))
    rows.append((ts, p))
rows.sort()
for ts, p in rows:
    print(f"{p}\t{ts:%d.%m.%Y}")
PYEOF

PHOTOS=(); DATES=()
while IFS=$'\t' read -r pth dte; do
  [ -n "$pth" ] && PHOTOS+=("$pth") && DATES+=("$dte")
done < "$TMP/order.tsv"
N=${#PHOTOS[@]}
[ "$N" -eq 0 ] && { echo "❌ Chưa có ảnh trong $SRC/."; exit 1; }
echo "▶ $N ảnh, theo dòng thời gian: ${DATES[0]} → ${DATES[$((N-1))]}"

# ---------------- 3 khung chữ ----------------
ffmpeg -y -loglevel error -f lavfi -i "$BG"  -t $TITLE_DUR -r $FPS -vf "$TITLE_F,format=yuv420p" -c:v libx264 -crf 18 "$TMP/card_a.mp4"
ffmpeg -y -loglevel error -f lavfi -i "$BG"  -t $END_DUR   -r $FPS -vf "$END_F,format=yuv420p"   -c:v libx264 -crf 18 "$TMP/card_y.mp4"
if [ -n "$AV_PNG" ]; then
  ffmpeg -y -loglevel error -f lavfi -i "$BG2" -loop 1 -i "$AV_PNG" -t $PS_DUR -r $FPS \
    -filter_complex "[1:v]format=rgba,fade=t=in:st=0.5:d=0.4:alpha=1[av];[0:v]$PS_F[bg];[bg][av]overlay=(W-w)/2:460,format=yuv420p" \
    -c:v libx264 -crf 18 -t $PS_DUR "$TMP/card_z.mp4"
else
  ffmpeg -y -loglevel error -f lavfi -i "$BG2" -t $PS_DUR -r $FPS -vf "$PS_F,format=yuv420p" -c:v libx264 -crf 18 "$TMP/card_z.mp4"
fi
echo "▶ Xong 3 khung chữ."

# ---------------- Ken Burns từng ảnh ----------------
i=0
for p in "${PHOTOS[@]}"; do
  D=$(python3 -c "print(int($PHOTO_DUR*$FPS))")
  if [ $((i % 2)) -eq 0 ]; then Z="min(zoom+0.00046,1.05)"; else Z="if(eq(on,0),1.05,max(zoom-0.00046,1.0))"; fi
  STAMP=""
  if [ "$SHOW_DATE" = "1" ]; then
    printf '%s' "${DATES[$i]}" > "$TMP/date_$i.txt"
    STAMP=",drawtext=fontfile='$FU':textfile='$TMP/date_$i.txt':fontsize=40:fontcolor=white@0.92:borderw=3:bordercolor=black@0.35:x=(w-text_w)/2:y=h-165:alpha='if(lt(t,0.5),0,min((t-0.5)/0.7,1))'"
  fi
  ffmpeg -y -loglevel error -i "$p" \
    -vf "scale=$((W*FIT/100/2*2)):$((H*FIT/100/2*2)):force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:black,scale=$((W*3/2)):$((H*3/2)),zoompan=z='$Z':d=$D:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${W}x${H}:fps=$FPS,setsar=1$STAMP,format=yuv420p" \
    -frames:v $D -c:v libx264 -preset veryfast -crf 16 -r $FPS "$TMP/seg_$(printf %03d $i).mp4"
  i=$((i+1)); printf "\r▶ Ken Burns: %d/%d " $i $N
done; echo ""

# ---------------- ghép + chuyển cảnh ----------------
SEGS=("$TMP/card_a.mp4"); for f in $(ls "$TMP"/seg_*.mp4 | sort); do SEGS+=("$f"); done
SEGS+=("$TMP/card_y.mp4" "$TMP/card_z.mp4")
DURS=($TITLE_DUR); for _ in $(seq 1 $N); do DURS+=($PHOTO_DUR); done; DURS+=($END_DUR $PS_DUR)
LAST=$(( ${#SEGS[@]} - 1 ))

ARGS=(); for f in "${SEGS[@]}"; do ARGS+=(-i "$f"); done
FC=""; prev="0:v"; acc=${DURS[0]}
for ((k=1; k<${#SEGS[@]}; k++)); do
  if [ $k -eq $LAST ]; then TT="$XF_LAST_TYPE"; TD=$XF_LAST; else TT="fade"; TD=$XF; fi
  off=$(python3 -c "print(round($acc-$TD,3))")
  FC="$FC[$prev][$k:v]xfade=transition=$TT:duration=$TD:offset=$off[x$k];"
  prev="x$k"; acc=$(python3 -c "print(round($acc+${DURS[$k]}-$TD,3))")
done
FC="${FC%;}"; TOTAL=$acc
echo "▶ Tổng ${TOTAL}s — đang ghép (bước lâu nhất)..."

MUSIC=""
for m in *.mp3 *.m4a *.wav; do [ -f "$m" ] && MUSIC="$m" && break; done

if [ -n "$MUSIC" ]; then
  echo "▶ Nhạc: $MUSIC"
  AI=${#SEGS[@]}
  FADE_ST=$(python3 -c "print(round($TOTAL-3,2))")
  ffmpeg -y -loglevel error "${ARGS[@]}" -stream_loop -1 -ss $MUSIC_START -i "$MUSIC" \
    -filter_complex "$FC;[$AI:a]atrim=0:$TOTAL,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=2,afade=t=out:st=$FADE_ST:d=3[a]" \
    -map "[$prev]" -map "[a]" \
    -c:v libx264 -preset fast -crf 20 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -t $TOTAL video.mp4
else
  echo "⚠️  Không thấy file nhạc — dựng video không nhạc."
  ffmpeg -y -loglevel error "${ARGS[@]}" -filter_complex "$FC" -map "[$prev]" \
    -c:v libx264 -preset fast -crf 20 -pix_fmt yuv420p -movflags +faststart video.mp4
fi

rm -rf "$TMP"
echo "✅ Xong! -> video.mp4 ($(du -h video.mp4 | cut -f1))"
