#!/usr/bin/env bash

# npm
sudo npm i npm@11.2.0 -g

# nginx
sudo apt update
sudo apt install nginx

if [[ -f /etc/nginx/sites-enabled/default ]] ; then sudo unlink /etc/nginx/sites-enabled/default ;fi
sudo mkdir -p /etc/nginx/locations


# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# env 
if [[ ! -z "$QUARTZ_PORT" ]]; then echo QUARTZ_PORT $QUARTZ_PORT; else QUARTZ_PORT=8000 ;fi
if [[ ! -z "$QUARTZ_CONTENT" ]]; then echo QUARTZ_CONTENT $QUARTZ_CONTENT; else QUARTZ_CONTENT=$DIR/content ;fi
if [[ ! -z "$QUARTZ_DOMAIN" ]]; then echo QUARTZ_DOMAIN $QUARTZ_DOMAIN; else QUARTZ_DOMAIN=quartz ;fi

echo QUARTZ_PORT $QUARTZ_PORT
echo QUARTZ_CONTENT $QUARTZ_CONTENT
echo QUARTZ_DOMAIN $QUARTZ_DOMAIN

sudo cp $DIR/default.conf /etc/nginx/conf.d/default.conf
#sudo cp $DIR/location-*.conf /etc/nginx/locations/

sed "/proxy_pass/s/127.0.0.1:[0-9]\+/127.0.0.1:$QUARTZ_PORT/"  $DIR/location-quartz.conf  | sudo tee /etc/nginx/locations/location-quartz-$QUARTZ_DOMAIN.conf
sudo sed -i "/quartz/s/quartz/$QUARTZ_DOMAIN/" /etc/nginx/locations/location-quartz-$QUARTZ_DOMAIN.conf

sudo service nginx restart
sudo nginx -t && sudo systemctl reload nginx

# run app

npm i --prefix $DIR

cd $DIR &&  npx quartz build  --serve --watch --port $QUARTZ_PORT  -d $QUARTZ_CONTENT


#echo "commit github update"

#cd $DIR
#git add --all
#git commit -m "update"
#git push origin main


