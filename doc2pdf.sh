#!/bin/sh
#taken from http://www.togaware.com/linux/survivor/Convert_MS_Word.html
DIR=$(pwd)
DOC=$DIR/$1
                                                                               
/soft/general/openoffice.org/openoffice.org3/program/swriter -invisible "macro:///Standard.Module1.ConvertWordToPDF($DOC)"
