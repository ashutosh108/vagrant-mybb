#!/bin/sh

CACHE_FILE_NAME=/vagrant/cache.sh
CACHE_VARS="login_at_host path_to_public_html"
DRY_RUN=0

prepare_cache() {
	rm "$CACHE_FILE_NAME"
	for i in $CACHE_VARS; do
		echo "Enter $i"
		read val
		eval "$i=$val"
		echo "$i=\"$val\"" >> $CACHE_FILE_NAME
		echo "cache var $i = $val"
	done
}

#### MAIN CODE ####

## prepare shell variables from cache or request them interactively

[ -f "$CACHE_FILE_NAME" ] && . "$CACHE_FILE_NAME" || prepare_cache


## prepare ssh identification

[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa
[ "$DRY_RUN" -eq 0 ] && ssh-copy-id "$login_at_host"


## copy and fix www files

if [ "$DRY_RUN" -eq 0 ]; then
	rsync -azv "$login_at_host":"$path_to_public_html"/ /var/www/html/ && tar -C /var/www/html -czf /vagrant/www.tar.gz .
else
	echo "Unpacking www.tar.gz"
	tar xzf /vagrant/www.tar.gz -C /var/www/html
fi
chown -R vagrant:www-data /var/www/html
chmod -R g+r /var/www/html
find /var/www/html -type d -execdir chmod g+x {} \+

## copy sql data

db_name=$(php -r 'include "/var/www/html/inc/config.php"; echo $config["database"]["database"];')
db_login=$(php -r 'include "/var/www/html/inc/config.php"; echo $config["database"]["username"];')
db_password=$(php -r 'include "/var/www/html/inc/config.php"; echo $config["database"]["password"];')

if [ "$DRY_RUN" -eq 0 ]; then
	ssh -C "$login_at_host" mysqldump --databases "$db_name" -u "$db_login" "-p$db_password" | gzip > /vagrant/sql.gz
fi
zcat /vagrant/sql.gz | mysql -u root -proot

## ensure new mysql user exists and have all rights (this host is only for this website, it's OK to grant all rights).

mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO '$db_login'@'localhost' IDENTIFIED BY '$db_password';"

#patch_files() {
#    for file; do
#        sed -i $file \
#            -e 's/^\\$wgServer\\s*=.*/$wgServer = "http:\\/\\/127.0.0.1:8080";/' \
#            -e 's/^\\$wgDBuser\\s*=.*/$wgDBuser = "root";/' \
#            -e 's/^\\$wgDBpassword\\s*=.*/$wgDBpassword = "root";/'
#    done
#}
#export -f patch_files
#find /var/www -name LocalSettings.php -execdir bash -c 'patch_files {}' \\;
