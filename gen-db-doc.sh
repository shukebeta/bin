#/bin/bash

set -ex

cd ~/Projects/yangtaoabc
git checkout master
git pull --ff
if [ $? -eq 0 ]; then
	exportAllDbStructure
	exportalldbdict.sh
	git add .
	git commit -am"automatically save db structure @ `date '+%Y-%m-%d %H:%M:%S'`" || true
	git push
else
    echo '!!!!!!!!!!!!!!!!Something wrong!'
fi
