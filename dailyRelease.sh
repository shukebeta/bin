#/bin/bash

set -ex
manualReleaseNote=""
[ "$2" != "" ] && manualReleaseNote=":${2}"
for proj in {background_shop,background_seller,front_app,mgmt_website}; do
    if [ -z ${1+x} ] || [ "$1" == "$proj" ]; then
		echo "Releasing ${proj}..."
		cd ~/bin/git/$proj
		git checkout master
		git pull --ff
		git fetch
		git merge origin/develop
		tagName=v`date '+%Y%m%d%H%M'` && git tag -a ${tagName} -m "Regularly release @ `date '+%Y-%m-%d %H:%M:%S'`${manualReleaseNote}"
		git push && git push origin ${tagName}
    fi
done
echo 'Releasing document...'
#gen-db-doc.sh
