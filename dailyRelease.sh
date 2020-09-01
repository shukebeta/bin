#/bin/bash

set -ex

cd ~/bin/git/background_shop
git checkout master
git pull --ff
git fetch
git merge origin/develop
if [ $? -eq 0 ]; then
	exportAllDbStructure
	exportalldbdict.sh
    git add .
	git commit -am"automatically save db structure @ `date '+%Y-%m-%d %H:%M:%S'`"
	git push
    git checkout develop
    git pull --ff
    git merge master
    git push
else
    echo '!!!!!!!!!!!!!!!!Something wrong!'
fi
cd ~/bin/git/front_app
git checkout master
git pull --ff
git fetch
git merge origin/develop
if [ $? -ne 0 ]; then
    echo '!!!!!!!!!!!!!!!!Something wrong @ front end!'
fi
git push
