#!/bin/bash
set -ex

for domain in {yangtaoabc.com,ytabc.com,youtrade.co.nz}; do
	cd /tmp/${domain}
	cp fullchain.cer fullchain.pem
	cp ${domain}.key privkey.pem
done;

scp -r /tmp/{{ytabc,yangtaoabc}.com,youtrade.co.nz} ytp-files:
rm -rfv /tmp/yangtaoabc.com
rm -rf /tmp/ytabc.com.previous || true
mv /tmp/ytabc.com /tmp/ytabc.com.previous
rm -rf /tmp/youtrade.co.nz.previous || true
mv /tmp/youtrade.co.nz /tmp/youtrade.co.nz.previous

#rm -rfv /tmp/{{ytabc,yangtaoabc}.com,youtrade.co.nz}
ssh ytp-files 'bash ~/publish/deployCert.sh'
