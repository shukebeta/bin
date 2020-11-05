if [ $# != 1 ]; then
  echo "Usage: signHttps yourdomain.com"
else
  sudo certbot certonly --manual -d *.${1} -d ${1} --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory
fi
