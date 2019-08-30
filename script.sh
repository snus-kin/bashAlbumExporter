#!/bin/bash
# written by martin barker, 2019
# www.martinbarker.me
# https://github.com/MartinBarker/bashAlbumExporter
shopt -s nullglob

filePath=$1
audioInputFormat=$2
imageFilename=$3
fullAlbumOption=$4
removeUpTo_char=$5
removeUpTo_offset=$6
declare -a filenames=()


echo "Welcome to Martin's audio exporter."
echo "format = $./script.sh filePath audioInputFormat imageFilename fullAlbumOption removeUpTo_char removeUpTo_offset"

#debug being#
echo "filePath = $filePath"
echo "audioInputFormat = $audioInputFormat"

# ~ functions ~ #

function render {
  
  # $1 = audioInputFormat
  echo "render : 1 = $1"

  # $2 = filePath
  echo "render : 2 = $2"

  # $3 = imageFilename
  echo "render : 3 = $3"

  # $4 = input filename
  echo "render : 4 = $4"

  # $5 = outputFilename
  echo "render : 5 = $5"

  if [[ "$1" = *mp3 ]]; then
    echo "audioInputFormat ends with mp3"
    #avi
    #ffmpeg -y -i "$2/$3" -i "$2/$4" -c:a copy "$2/$5.avi"
    #youtube ready mkv
    #ffmpeg -loop 1 -framerate 2 -i 'front.jpg' -i 'output.mp3' -vf "scale=2*trunc(iw/2):2*trunc(ih/2),setsar=1" -c:v libx264 -preset medium -tune stillimage -crf 18 -c:a copy -shortest -pix_fmt yuv420p outputReEncoded.mkv          
    ffmpeg -loop 1 -framerate 2 -i "$2/$3" -i "$2/$4" -vf "scale=2*trunc(iw/2):2*trunc(ih/2),setsar=1" -c:v libx264 -preset medium -tune stillimage -crf 18 -c:a copy -shortest -pix_fmt yuv420p "$2/$5.mp4"          


  elif [[ "$1" == *flac ]]; then
    echo "audioInputFormat ends with flac"
  else
    echo "audioInputFormat ends with something unrecognized"
  fi
}

function individualRender {
    echo "Exporting individual songs."
    echo "filePath = $filePath"
    echo "audioInputFormat = $audioInputFormat"

    for pathToInput in $filePath/*.$audioInputFormat 
    #for filepath in $filePath/*.$audioInputFormat
    do
  	  echo "exporting audio file input located at = $pathToInput"

      #get dir where file is located
      DIR=$(dirname "${pathToInput}")
      #get the individual input audio file's filename 
      filename=$(basename "${pathToInput}")
      echo "input filename = $filename"

      #set default outputFilename so if user doesn't specify a new filename
      outputFilename=$filename

      #sanitize output filename by replacing all single-quotes with '\''
      #example: artist's song.mp3 would become artist'\''s song.mp3
      tr "'" "'\'" <<<"$outputFilename"  ## With "tr"

      printf "starting outputFilename = \n$outputFilename\n"
      #remove file extension from filename
      outputFilename="${outputFilename%.*}"

      #format outputFilename if removeUpTo_char is present
      if [[ "$removeUpTo_char" ]]; then
        #remove letters up to the first occurance of this char: removeUpTo_char
        outputFilename="${outputFilename#*$removeUpTo_char}"
        echo "  removeUpTo_char was found, outputFilename = $outputFilename"
      fi

      #format outputFilename if removeUremoveUpTo_offsetpTo_char is present
      if [[ "$removeUpTo_offset" ]]; then 
        #remove as many characters from the start of the filename as specified in this int: removeUpTo_offset
        outputFilename="${outputFilename:$removeUpTo_offset}"
        echo "  removeUpTo_offset  was found, outputFilename = $outputFilename"
      fi

      #format outputFilename based on removeUpTo_offset (will do nothing if removeUpTo_offset = 0 )
      #outputFilename="${outputFilename:$removeUpTo_offset}"
      printf "ending outputFilename = \n$outputFilename\n"

      #export audio file as video file
  	  render "$audioInputFormat" "$filePath" "$imageFilename" "$filename" "$outputFilename"

  	  #add filename to array
  	  #filenames+=("$filename")
      printf "\n"
    done
    
}

function fullAlbum {
  echo "Exporting full album."
  
  #get array of filenames
  for pathToInput in $filePath/*.$audioInputFormat 
  do
      #get dir where file is located
      DIR=$(dirname "${pathToInput}")
      #get the individual input audio file's filename 
      filename=$(basename "${pathToInput}")
      echo "input filename = $filename"
      filenames+=("$filename")
  done 

  #store dateTime since epoch in variable
  dateTime=$(date +%s%N | cut -b1-13)
  #echo "dateTime = $dateTime"
  
  #construct concat string used in ffmpeg command
  concatString="concat:"
  #for each file in filenames array 
  for filename in "${filenames[@]}"
	do
    echo "f = $filename"
    if [ "$filename" != "concatAudio.mp3" ]; then
      concatString="$concatString$filePath/$filename|"
    fi
  done

  #concatString="concat:$filePath/8. Bob's Song.mp3|4.T.J..mp3"
  echo "concatString = $concatString"

  #cleanup leftover concatAudio.mp3 if it already exists
  rm concatAudio.mp3

	#concatenate all audio files into one long audio file
  ffmpeg -i "$concatString" -acodec copy $filePath/concatAudio.mp3

  #render video using this long audio file
  #old
  #ffmpeg -y -i "$filePath/$imageFilename" -i "$filePath/concatAudio.mp3" -c:a copy "$filePath/fullAlbum.avi"
  ffmpeg -loop 1 -framerate 2 -i "$filePath/$imageFilename" -i "$filePath/concatAudio.mp3" -vf "scale=2*trunc(iw/2):2*trunc(ih/2),setsar=1" -c:v libx264 -preset medium -tune stillimage -crf 18 -c:a copy -shortest -pix_fmt yuv420p "$filePath/fullAlbum.avi"   

  rm concatAudio.mp3
}

# ~ main ~ #
if (( fullAlbumOption == 0 )); then
  #export individual songs
  individualRender

elif (( fullAlbumOption == 1 )); then
  #export individual songs
  individualRender

  #export full album
  fullAlbum

elif (( fullAlbumOption == 2 )); then
  #export only full album
  fullAlbum

fi