#!/bin/bash

# a simple script to download an epub version of a given web page from http://fivefilters.org/kindle-it/
# or (optionally) generate an epub version of the given web page using Pandoc (http://pandoc.org/)

# change the next line to the absolute output path where you would like the epub to be saved inlcuding the trailing '/'
savepath="$HOME/Documents/"

# OPTIONAL: the absolute path to the list of domains for which you want epubs with images (less pretty output)
# Use one fully qualified domain name (https://en.wikipedia.org/wiki/Fully_qualified_domain_name) per line.
# Pandoc must be installed to use this feature.
pandoclist="$HOME/.config/pandoclist"

now=$(date +"%s")                       # store the current time
url=$1                                  # store the input URL
furl=${url#*://}                        # remove the 'http://' or 'https://' from the input URL
domain=$( echo "$furl" |cut -d/: -f1 )  # get the domain for checking against Pandoc list

# the next line contains the options to pass to Five Filters
durl='http://fivefilters.org/kindle-it/send.php?context=download&format=epub&url='
durl+=$furl                             # construct the full URL of the epub request URL

oname=$(basename $url)                  # save the last part of the URL, which we will use to name the epub
oname="${oname%.*}"                     # remove the file extension (eg .html)
oname+=-"$now"			        # add a timestamp to prevent overwriting of files with same name
oname+='.epub'                          # add the .epub file extension to the output name
opath=$savepath$oname                   # define the absolute path to the output file

if grep -Fxq $domain $pandoclist        # check for match in the Pandoc list
then
    pandoc -r html $url -t epub -o $opath       # generate the epub and store it in the specified directory
else
    wget -b -q $durl -O $opath                  # download the epub and store it in the specified directory
fi
