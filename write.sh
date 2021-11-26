#!/bin/sh

if [$# -eq 0 ] 

then

    minipro -p AT28C256 -w $1

else

    minipro -p AT28C256 -w a.out

fi
