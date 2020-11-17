#/bin/bash
sname=$(basename $0)
if [ "${sname}" == "dailyReleaseMaster.sh" ]; then
  from=develop
  to=master
elif [ "${sname}" == "dailyReleaseDevelop.sh" ]; then
  from=local
  to=develop
else
  dailyReleaseDevelop.sh $1 $2
  dailyReleaseMaster.sh $1 $2
  exit 0
fi
set -ex
manualReleaseNote=""
[ "$2" != "" ] && manualReleaseNote=" Release Note: ${2}"
for proj in {background_shop,background_seller,front_app,mgmt_website}; do
    if [ -z ${1+x} ] || [ "$1" == "$proj" ]; then
		echo "Releasing ${proj}..."
		cd ~/bin/git/$proj
		git checkout ${to}
		git pull --ff
		git fetch
		git merge origin/${from}
		tagName=v${to:0:1}`date '+%Y%m%d%H%M'` && git tag -a ${tagName} -m "Regularly ${to} branch release @ `date '+%Y-%m-%d %H:%M:%S'`${manualReleaseNote}"
		git push && git push origin ${tagName}
    fi
done
#echo 'Releasing document...'
#gen-db-doc.sh
