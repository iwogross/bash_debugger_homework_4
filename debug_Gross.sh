#!/bin/bash

# bashdb - a bash debugger

# Driver Script: concatenates the preamble and the target script
# and then executes the new script.

echo 'bash Debugger version 1.0'

_dbname=${0##*/}

if (( $# < 1)) ; then
    echo "$_dbname: Usage: $_dbname filename" >&2
    exit
fi

_guineapig=$1

if [ ! -r $1 ]; then
    echo "$_dbname: Cannot read file '$_guineapig'." >&2
    exit 1
fi

shift

_tmpdir=/tmp
_libdir=.
_debugfile=$_tmpdir/bashdb.$$ #temporary firle for script that is
    #being debugged
cat $_libdir/bashdb.pre $_guineapig > $_debugfile
exec bash $_debugfile $_guineapig $_tmpdir $_libdir "$@"

# bashdb preamble
# This file gets prepended to the shell script being debugged.
# Arguments:
# $1 = the name of the original guinea pig script
# $2 = the directory where temporary files are stored
# $3 = the directory where bashdb.pre and bashdb.fns are stored
_debugfile=$0
_guineapig=$1
_tmpdir=$2
_libdir=$3
shift 3
source $_libdir/bashdb.fns
_linebp=
let _trace=0
let _i=1
while read; do
_lines[$_i]=$REPLY
let _i=$_i+1
done < $_guineapig
trap _cleanup EXIT
let _steps=1
trap '_steptrap $(( $LINENO -29 ))' DEBUG
:

