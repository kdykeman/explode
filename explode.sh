#!/usr/bin/env bash

set -eu

usage() {
  echo "Usage: `basename $0` [-d depth] target

  -d DEPTH                  Limit recursive extraction to a specified depth" >&2
  exit 1
}

pushd () {
  command pushd "$@" > /dev/null
}

popd () {
  command popd "$@" > /dev/null
}

explode() {
  local target="$1"
  local depthleft="$2"

  if [ $depthleft -eq 0 ]; then
    return
  fi
  if [ -f "$target" ] ; then
    ((depthleft--))
    echo
    echo "Exploding $target."
    explodeFile "$target" $depthleft
  elif [ -d "$target" ] ; then
    for file in `find -E $target -type f -iregex ".*\.(zip|jar|ear|war|sar|tgz|gz|tar|bz2|gem|xz)"` ; do
      explode $file $depthleft
    done
  else
    echo "Could not find $target."
  fi
}

explodeFile() {
  local target="$1"
  local depthleft="$2"

  local ftype=`file -b --mime-type $target`
  local cmd=""

  local dirname=`dirname $target`
  local filename=`basename $target`
  local extension="${filename##*.}"
  local contents="$filename-contents"

  pushd $dirname
  if [ ! -d $contents ] ; then
    mkdir "$contents"
  fi
  pushd $contents

  if [ $ftype = "application/x-gzip" ] ; then
    if [ `basename $filename .gz` != $filename -a `basename $filename .tar.gz` = $filename ] ; then
      cmd="cp ../$filename . && gunzip $filename"
    else
      cmd="tar xzf ../$filename"
    fi
  elif [ $ftype = "application/x-bzip2" ] ; then
    cmd="tar xzf ../$filename"
  elif [ $ftype = "application/x-xz" ] ; then
    cmd="tar xzf ../$filename"
  elif [ $ftype = "application/x-tar" ] ; then
    cmd="tar xf ../$filename"
  elif [ $ftype = "application/zip" ] ; then
    if [ $extension = "jar" ] ; then
      cmd="jar xf ../$filename"
    else
      cmd="unzip -qqu ../$filename"
    fi
  elif [ $ftype = "application/java-archive" ] ; then
    cmd="jar xf ../$filename"
  fi

  echo `pwd`
  echo $cmd
  eval $cmd
  popd
    explode $contents $depthleft
  popd
}

DEPTH=-1
while getopts "d:" opt; do
  case $opt in
    d)
      DEPTH="$OPTARG"
      re='^[1-9][0-9]*$'
      if ! [[ $DEPTH =~ $re ]] ; then
        echo "error: Not a valid depth: $DEPTH" >&2; exit 1
      fi
      echo "The value provided for depth is $OPTARG" >&2
      ;;
    *)
      usage
      ;;
  esac
done
shift $(($OPTIND - 1))
if [ $# -ne 1 ]; then
  usage
fi
explode $1 $DEPTH
