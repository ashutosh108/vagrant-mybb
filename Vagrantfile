Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "512"
  end

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provision "shell", inline: <<-SHELL
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get update

    debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
    PKGS="apache2 libapache2-mod-php5.6 mysql-client mysql-server php5.6-mbstring php5.6-xml php5.6-mysql"
    apt-get -y --no-install-recommends install $PKGS

    a2enmod rewrite
    install -m=644 /vagrant/apache2.conf /etc/apache2/
    systemctl reload apache2 # required for php to see php-mbstring and php-xml installed

    find /var/www/html -mindepth 1 -xdev -delete 2>/dev/null
    /vagrant/provision.sh
  SHELL
end
