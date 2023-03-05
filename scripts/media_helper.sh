#!/bin/bash
## Some routines that use ffmpeg to capture audio/video from computer nd outputs it to a twitch stream or a file.
## Do NOT source, usage: bash media_helper.sh COMMAND ARGS

# *USAGE : __get_resolution
# Returns the resolution (format widthxheigth) into variable $MY_RESOLUTION.
# Crashes if more than 1 monitor is connected.
__get_resolution() {
  local -a resolutions=(
    `xrandr --listmonitors | sed -nr 's".* ([[:digit:]]+)/[[:digit:]]+x([[:digit:]]+)/[[:digit:]]+.*"\1x\2"p'`
  )
  if [[ "${#resolutions[@]}" == 0 ]] || [[ -z "${resolutions[0]}" ]]; then
    echo "[ERROR] cannot decide correct resolution"
    xrandr --listmonitors
    exit 1
  fi
  MY_RESOLUTION="${resolutions[0]}"
}

## *USAGE : x11_to_twitch STREAM_KEY_FILE
## Original version at : https://wiki.archlinux.org/index.php/Streaming_to_twitch.tv
## Modified to remove audio stream and other options I do not understand :/
## STREAM_KEY_FILE is encrypted, gpg will request password to decrypt it.
x11_to_twitch() {
  local fps="30" # target FPS
  local gop="$(( fps * 2 ))" # gop = group of images = number of consecutive frames between keyframes
  local gop_min="$fps" # min frames between key frames

  local stream_server="live-fra02" # see https://stream.twitch.tv/ingests for list
  local stream_file="${1}" # key will be passed as an agument from the command line
  [[ -f "$stream_file" ]] || return 1
  local stream_key="`gpg --quiet --decrypt --batch "$stream_file"`"

  local -a input_opts=(
    -f "x11grab"
    -video_size "$MY_RESOLUTION"
    -framerate "${fps}" 
    # https://stackoverflow.com/a/57904380
    -probesize "128M" 
    -i ":0.0"
  )
  local -a output_opts=(
    -vcodec "libx264"
    -g "${gop}" -keyint_min "${gop_min}"
    # Average variable birate for output ?
    -b:v "3000k"
    -f "flv" 
    #-s "1280x720" 
    -s "1920x1080" 
    -preset "ultrafast" 
    #-tune "film"
    -tune "zerolatency"
    -threads "6"
    -strict "normal"
  )
  set -x
  ffmpeg \
      -loglevel "warning" \
      -thread_queue_size 32 \
      "${input_opts[@]}" -map 0:v ${output_opts[@]} \
      "rtmp://${stream_server}.twitch.tv/app/${stream_key}"
}


## *USAGE : pulse_to_file
## Broken using an external USB audio device.
## Requires the manual device selection with `pavucontrol` to work ...
pulse_to_file() {
  local file_out="/tmp/capture_audio"
  [[ -f "$file_out" ]] && rm "$file_out"

  set -x
  ffmpeg -f pulse -i default -filter:a "volume=10dB" /tmp/pulse.wav
}

## *USAGE : x11_to_file [[--no-audio]] OUTPUT_FILE
## Captures x11 and saves to file.
x11_to_file() {
  local fps="30" # target FPS
  local gop="$(( fps * 2 ))" # gop = group of images = number of consecutive frames between keyframes
  local gop_min="$fps" # min frames between key frames
  if [[ "$1" == "--no-audio" ]]; then
    local noaudio=1
    shift
  fi
  local file_out="${1:-captured_video}"
  [[ -f "$file_out" ]] && rm "$file_out"

  if [[ -z "$noaudio" ]]; then
    # pactl set-default-source alsa_output.usb-GFEC_ASSP_MyAMP-01.iec958-stereo.monitor
    local -a audio_input_opts=(
      -f "pulse"
      -i "default"
    )
    #-acodec aac/libvorbis -> Produces glitchy audio
    #-acodec copy -> cannot be used to capture audio
    local -a audio_output_opts=(
      -map 1:a
      -filter:a "volume=40dB" # so that record stream has more or less same volume as real thing
      -acodec aac
      -b:a 256k
      #-ar "48000"
    )
  fi
  local -a video_input_opts=(
    -f "x11grab"
    -video_size "$MY_RESOLUTION"
    -framerate "${fps}" 
    # https://stackoverflow.com/a/57904380
    -probesize "128M" 
    -i ":0.0"
  )
  local -a video_output_opts=(
    -map 0:v
    -vcodec "libx264"
    -pix_fmt yuv420p
    -b:v "5000k"
    -f "mp4" 
    -preset "ultrafast" 
    -tune "zerolatency"
    -threads "6"
    -strict "normal"
  )
  set -x
  ffmpeg \
      -loglevel "warning" \
      -thread_queue_size 32 \
      "${video_input_opts[@]}" \
      "${audio_input_opts[@]}" \
      "${video_output_opts[@]}" \
      "${audio_output_opts[@]}" \
      "$file_out"
}

## *USAGE : reencode_to_reduce_size INPUT_FILE
## Useful to preprocess videos before sending them to whatsapp.
reencode_to_reduce_size() {
  local inputfile="$1"
  local inputname="`basename "$1"`"
  local outputfile="`dirname "$1"`/${inputname%.*}_reencoded.${inputname##*.}"
  [[ -f "$inputfile" ]] || return 1
  [[ -f "$outputfile" ]] && rm "$outputfile"
  ffmpeg -i "$inputfile" -vcodec libx264 -crf 25 "$outputfile"
}

## *USAGE : remove_noise_audio INPUT_FILE
## Useful to clean and emplify recordings from phone.
remove_noise_audio() {
  local inputfile="$1"
  local inputname="`basename "$1"`"
  local outputfile="`dirname "$1"`/${inputname%.*}_cleaned.${inputname##*.}"
  local temp_proc="`mktemp`"
  local temp_proc2="`mktemp`"
  [[ -f "$inputfile" ]] || return 1
  [[ -f "$outputfile" ]] && rm "$outputfile"
  sox "$inputfile" "$temp_proc" highpass 800
  sox "$temp_proc" "$temp_proc2" lowpass 8000
  sox -v 3.0 "$temp_proc2" "$outputfile"
  # To ouput frequenct spectre with a highpass filter
  #ffmpeg -i kawa_zx9r_engine_noise_raw_20230221_2.m4a \
  #  -filter_complex "[0:a]highpass=frequency=400[a1];[a1]asplit[a2][a3];[a3]showfreqs=s=1920x1080[v]" \
  #  -map '[v]' -map '[a2]' -c:v libx264 -preset slow kawa_zx9r_engine_spectral_20230221_2.mp4
}

main() {
  local command="$1"
  shift
  __get_resolution
  "$command" "$@"
}
main "$@"

