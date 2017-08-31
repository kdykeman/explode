#!/usr/bin/env bash

set -eu

function explode {
    local target="$1"
    echo "Exploding $target."
    if [ -f "$target" ] ; then
        explodeFile "$target"
    elif [ -d "$target" ] ; then
        for file in `find -E $target -type f -iregex ".*\.(zip|jar|ear|war|sar|tgz|gz|tar|bz2|gem|xz)"` ; do
          explode $file
        done
    else
        echo "Could not find $target."
    fi
}

function explodeFile {
    local target="$1"
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
    explode $contents
    popd
}

#rbenv shell $(rbenv global)
explode $1
