#!/usr/bin/env bash

# npm
sudo npm i npm@11.2.0 -g

# nginx
sudo apt update
sudo apt install nginx

sudo unlink /etc/nginx/sites-enabled/default
sudo mkdir -p /etc/nginx/locations



# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )



sudo cp $DIR/default.conf /etc/nginx/conf.d/default.conf
sudo cp $DIR/location-*.conf /etc/nginx/locations/

sudo service nginx restart
sudo nginx -t && sudo systemctl reload nginx

# run app

npm i
#npx quartz build --serve --port 8002
npx quartz build --serve --watch --port 8002  -d $DIR/content

echo "commit github update"

#cd $DIR
#git add --all
#git commit -m "update"
#git push origin main


