#!/bin/bash


print_usage() {
  printf "Usage: ./backupgnome [ACTION] [OPTIONS ...]\n\n" 
  printf "Action:          	-b , --backup , --back 	to start backup \n                 	-r, --restore , --rest 	to restore backup\n                 	-h , --help             to get this help page\n\n"
  printf "Options(""'""-b""'""&""'""-r""'"") :	-f [FILE] file to store the backup in and to restore from  (DEFAULT: current directory and file name ""'""gnomebackup.tar.gz""'"" )\n"
  printf "Options(""'""-b""'""):		-e [DIRECTORY] location to copy the gnome extentions from  (DEFAULT: ~/.local/share/gnome-shell/extensions/ )\n"
  printf "              		-d [dconf~DIR] directory in dconf. learn more at ""'""dconf help""'"" or ""'""man dconf""'""  (DEFAULT: / )\n"
  printf "              		-A , -S , -E Backup All the things, only Settings or only Extentions (DEFAULT: -A )\n"
  printf "Options(""'""-b""'"")(preset):	-u Preset for very cautious people. \n 			Sets -d dconf directory to ""'""/org/gnome/shell/extensions/""'"" and -e extention directory to ""'""~/.local/share/gnome-shell/extensions/""'"" \n\n"
  printf "Good to know:		If the script runs without any action specified, it will decide for it self, what to do.\n			If it finds a ""'""gnomebackup.tar.gz""'"" int its directory, it will try to load it.\n			If it does not find any, it will strat creating a new backup \n\n"
  exit 0
}

backup() {

# checking $dconf
  if [ ! "${dconf:(-1)}" == "/" ] || [ ! "${dconf:0:1}" == "/" ]; then 
    echo "${dconf} has to be a directory path (starting and ending with '/')" 1>&2
    exit 1
  fi

# checking $file
  file=$(eval echo "${file}")
  if [ -f "${file}" ]; then
    echo "${file} already exists"

    if [ ! -w "${file}" ]; then
      echo "${file} is not writable" 1>&2
      exit 1
    fi
    read -p "Do you want to override ${file} (y/n)? " answer
    case ${answer:0:1} in
      y|Y )
        echo Yes
        ;;
      * )
        echo No
        exit 0
         ;;
    esac


  elif [ -d "$(dirname "$file")" ] ; then

    if [ ! -w "$(dirname "$file")" ]; then
      echo "The parent directory  $(dirname "$file") of file ${file} can not be written to!" 1>&2
      exit 1
    fi

  fi

extdir=$(eval echo "${extdir}")

#create temporary directory
  while
    tempfile="$(dirname "$file")/gnome-backup-temp-${RANDOM}-${RANDOM}" # find name for tempfile in parent of $file that is not currently used
    [ -d "${tempfile}" ]                                                # this is the construct for a bash do-while
  do
    :
  done
  echo $tempfile
  mkdir -m 0777 -p "$tempfile"

# save settings of variables vor easyer restoration
  echo dconf='"'"$dconf"'"' >> "${tempfile}/vars"
  echo extdir='"'"$extdir"'"' >> "${tempfile}/vars"

  if [ "${sel}" == "A" ] || [ "${sel}" == "S" ]; then
    echo "Backing up dconf:${dconf}"
    dconf dump "$dconf" > "${tempfile}/extension-settings.dconf"
  fi

  if [ "${sel}" == "A" ] || [ "${sel}" == "E" ]; then
    echo "Backing up extentions:${extdir}"
    mkdir -m 0777 -p "${tempfile}/extentions/"
    cp -rfv "${extdir}." "${tempfile}/extentions/"
    chmod 0777 "${tempfile}/extentions/*"
  fi

  tar cvzf $file -C $tempfile . # Cannot use "${var}" construct because quotes breake tar 

  rm -fr "${tempfile}"

  echo "Success! Your backup is available at :${file} "
}

restore() {

# checking $file
  file=$(eval echo "${file}")
  if [ ! -f "${file}" ]; then
    echo "${file} does not exist" 1>&2
    exit 1
  fi
  if [ ! -r "${file}" ]; then
    echo "${file} is not readable" 1>&2
    exit 1
  fi
# create temporary directory
  while
    tempfile="$(dirname "$file")/gnome-backup-temp-${RANDOM}-${RANDOM}" # find name for tempfile in parent of $file that is not currently used
    [ -d "${tempfile}" ]                                                # this is the construct for a bash do-while
  do
    :
  done

  mkdir -m 0777 -p "$tempfile"

  tar -xvf "${file}" -C "$tempfile"

  if [ ! -f "${tempfile}/vars" ]; then
    echo "The backup archive is broken!" 1>&2
    exit 1
  fi

  source "${tempfile}/vars"

  if [ -d "${tempfile}/extentions/" ]; then
   echo "copying extentions"
   cp -rfv "${tempfile}/extentions/." "${extdir}"
  fi

  if [ -f "${tempfile}/extension-settings.dconf" ]; then
   echo "loading dconf" 
   dconf load "$dconf" < "${tempfile}/extension-settings.dconf"
  fi

  rm -fr "${tempfile}"
  echo "Success! Backup ${file} fully loaded!"

}


 ### Get working directory into $DIR
SOURCE='${BASH_SOURCE[0]}'
while [ -h '$SOURCE' ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR='$( cd -P '$( dirname '$SOURCE' )' >/dev/null 2>&1 && pwd )'
  SOURCE='$(readlink '$SOURCE')'
  [[ $SOURCE != /* ]] && SOURCE='$DIR/$SOURCE' # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR='$( cd -P '$( dirname '$SOURCE' )' >/dev/null 2>&1 && pwd )'
DIR=$(eval echo "${DIR}")

backup=false
restore=false

while getopts 'hbr-:' flag ; do
  case "${flag}" in
    h)
       print_usage
       break
       ;;
    b)
       backup=true
       break
       ;;
    r)
       restore=true
       break
       ;;
    -) case "${OPTARG}" in
         help)
                     print_usage
                     break
                     ;;
         backup|back)
                     backup=true
                     break
                     ;;
         restore|rest)
                     restore=true
                     break
                     ;;
       esac
       ;;
  esac
done

if $backup && $restore; then 
  echo "What the fuck are you trying to do?!?!? RTFM!!!" 1>&2
  exit 1
elif ! $backup && ! $restore; then
  if [ -f "${DIR}/gnomebackup.tar.gz" ]; then
    restore=true
  else
    backup=true
  fi
fi

if $backup; then
  dconf="/"
  file=${DIR}/gnomebackup.tar.gz
  extdir="~/.local/share/gnome-shell/extensions/"
  sel="A"
  while getopts 'f:d:e:ASEu' flag ; do
    case "${flag}" in
        f) file="${OPTARG}";;
        d) dconf="${OPTARG}";;
	e) extdir="${OPTARG}";;
        A) sel="A";; # backup everything
        S) sel="S";; # only backup settings
        E) sel="E";; # only backup extentions
        u)  # only back up extentions from ~/.local/share/gnome-shell/extensions/
            # can be overwridden by 'd' and 'e'
           if [ "${dconf}" == "/" ]; then dconf="/org/gnome/shell/extensions/"; fi
           if [ "${extdir}" == "~/.local/share/gnome-shell/extensions/" ]; then extdir="~/.local/share/gnome-shell/extensions/"; fi
           ;;
    esac
  done
  if [ ! "${extdir:(-1)}" == "/" ]; then
    extdir="${extdir}/"
  fi
  backup

elif $restore; then
  file=${DIR}/gnomebackup.tar.gz
  while getopts 'f:' flag ; do
    case "${flag}" in
        f) file="${OPTARG}";;
    esac
  done
  restore
fi




