#/bin/bash

set -ex

cd ~/bin/git/background_shop
git checkout master
git pull --ff
git fetch
git merge origin/develop
if [ $? -eq 0]; then
	exportAllDbStructure
	exportalldbdict.sh
	git commit -am"automatically save db structure @ `date '+%Y-%m-%d %H:%M:%S'`"
	git push
fi
cd ~/bin/git/front_app
git checkout master
git pull --ff
git fetch
git merge origin/develop
git push
