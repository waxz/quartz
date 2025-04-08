#!/usr/bin/env bash

# npm
#sudo npm i npm@11.2.0 -g

# nginx
if ! which nginx &>/dev/null; then
    sudo apt update && sudo apt install nginx apache2-utils
fi

if [[ -f /etc/nginx/sites-enabled/default ]]; then sudo unlink /etc/nginx/sites-enabled/default; fi
sudo mkdir -p /etc/nginx/locations

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

# env

if tty -s; then
  echo "I am on a TTY"
  IS_TTY=true
else
  echo "I am NOT on a TTY"
  IS_TTY=false

fi

DOCKER_TTY=""
if $IS_TTY; then
  DOCKER_TTY="-it"
fi

PORT=8000
CONTENT=$DIR/content

NGINX_DOMAIN=quartz
NGINX_USER=quartz
NGINX_PSW=quartz

if [[ ! -z "$QUARTZ_PORT" ]]; then PORT=$QUARTZ_PORT; fi
if [[ ! -z "$QUARTZ_CONTENT" ]]; then CONTENT=$QUARTZ_CONTENT; fi
if [[ ! -z "$QUARTZ_DOMAIN" ]]; then NGINX_DOMAIN=$QUARTZ_DOMAIN; fi

if [[ ! -z "$QUARTZ_USER" ]]; then NGINX_USER=$QUARTZ_USER; fi
if [[ ! -z "$QUARTZ_PSW" ]]; then NGINX_PSW=$QUARTZ_PSW; fi

echo PORT $PORT
echo CONTENT $CONTENT
echo NGINX_DOMAIN $NGINX_DOMAIN

echo NGINX_USER $NGINX_USER
echo NGINX_PSW $NGINX_PSW

if [ ! -f /etc/nginx/.htpasswd ]; then sudo htpasswd -bcB -C 10 /etc/nginx/.htpasswd $NGINX_USER $NGINX_PSW; else sudo htpasswd -bB -C 10 /etc/nginx/.htpasswd $NGINX_USER $NGINX_PSW; fi

sudo cp $DIR/default.conf /etc/nginx/conf.d/default.conf
#sudo cp $DIR/location-*.conf /etc/nginx/locations/

sed "/proxy_pass/s/127.0.0.1:[0-9]\+/127.0.0.1:$PORT/" $DIR/location-quartz.conf | sudo tee /etc/nginx/locations/location-quartz-$NGINX_DOMAIN.conf
sudo sed -i "/quartz/s/quartz/$NGINX_DOMAIN/" /etc/nginx/locations/location-quartz-$NGINX_DOMAIN.conf

sudo service nginx restart
sudo nginx -t && sudo systemctl reload nginx

# run app

# npm i --prefix $DIR

# cd $DIR &&  npx quartz build  --serve --watch --port $PORT  -d $CONTENT

docker run -v $CONTENT:$CONTENT -v $DIR:$DIR -w $DIR -p $PORT:$PORT --rm $DOCKER_TTY node:22 bash -c "npm install -g npm@11.2.0 && npm i && npx quartz build  --serve --watch --port $PORT  -d $CONTENT"

#echo "commit github update"

#cd $DIR
#git add --all
#git commit -m "update"
#git push origin main
