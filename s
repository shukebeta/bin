#!/bin/bash
#set -ex
# 搜索关键字要么不用引号包裹，要么使用双引号包裹。请不要使用单引号包裹

pname=`basename $0`

if [ $pname = "g" -a $# -lt 1 ];then
    echo "Usage: $pname 'keyword' [-i]"
    exit
fi
if [ $pname = "s" -a $# -lt 3 ];then
    echo "Usage: $pname sourcestring targetstring path"
    exit
fi

exclude_dir_list=(assets node_modules dist \.idea \.git vendor public MathJax PHPExcel phpQuery PHPQRCode node_modules data database Zend min css test)
exclude_dir_list=(node_modules dist \.idea \.git vendor public MathJax PHPExcel phpQuery PHPQRCode node_modules data database Zend min css test)
exclude_file_list=("*ttf" "*map" "*gif" "*jpg" "*gdf")
filter_list=('Binary file' '\(lib\|\.min\)\.js' 'custom\.css' 'main_style\.css' 'template_build' '.*-min\.js' 'storage/debugbar')

excludeDirStr=""
for dir in "${exclude_dir_list[@]}"; do
   excludeDirStr="${excludeDirStr} --exclude-dir='${dir}'"
done

excludeFileStr=""
for file in "${exclude_file_list[@]}"; do
   excludeFileStr="${excludeFileStr} --exclude='${file}'"
done

filterStr=""
for keyword in "${filter_list[@]}"; do
   filterStr="${filterStr} | grep -v '${keyword}'"
done


key="${1/\"/\\\"}"
key="${key/\`/\\\`}"
dir=$2
[ "${dir}" == "" ] && dir="."
if [ $pname = "g" ]; then
    cmd="grep $excludeDirStr $excludeFileStr --color=always -nre \"${key}\" \"${dir}\" $filterStr"
	#echo $cmd
    bash -c "$cmd"
else
    replace="${2/\"/\\\"}"
    replace="${replace/\`/\\\`}"
    filelistcmd="grep $excludeDirStr $excludeFileStr -rl \"${key}\" \"${3}\" $filter_str"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cmd="sed -i '' \"s/${key}/${replace}/g\" \$($filelistcmd)"
    else
        cmd="sed -i \"s/${key}/${replace}/g\" \$($filelistcmd)"
    fi
	#echo $cmd
    bash -c "$cmd"
fi

