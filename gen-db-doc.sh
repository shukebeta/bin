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
    tagName=v`date '+%Y%m%d%H%M'` && git tag -a ${tagName} -m "Auto release @ `date '+%Y-%m-%d %H:%M:%S'`"
    git push && git push origin ${tagName}
else
    echo '!!!!!!!!!!!!!!!!Something wrong!'
fi
