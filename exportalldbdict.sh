#!/bin/bash

set -ex

databases=(IDServer YangtaoStandard YangtaoCommodity YangtaoOrders YangtaoMerchant)

for db in "${databases[@]}";
do
	list=`mysql -e "use ${db}; show tables;"|sed '1d'`
	while IFS= read -r line; do
		exportdbdict $db $line
	done <<< "$list"
done;
