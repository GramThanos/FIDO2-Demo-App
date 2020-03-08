# FIDO2 Demo App
A demo Ruby on Rails application featuring FIDO2 password-less login

![Preview](https://raw.githubusercontent.com/GramThanos/FIDO2-Demo-App/master/preview.gif)

___


### Setup

To fully set up this web application you will need a domain name and an SSL certificate.

#### Install on Ubuntu
Prepare your Ubuntu system by installing Ruby, NodeJs, Yarn, Rails and dependencies

```cmd
# Prepare Ubuntu
sudo apt update
sudo apt upgrade -y

sudo apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev
sudo apt install -y ruby-full sqlite3 libsqlite3-dev curl git

# Prepare nodejs
curl -sL https://deb.nodesource.com/setup_13.x | sudo bash

# Prepare yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install nodejs and yarn
sudo apt update && sudo apt install -y nodejs yarn

# Install rails
sudo gem install rails
```

Enter the folder where you want to place the app's folder (e.g. `cd ~/Downloads/`) and clone this GitHub repo.

```cmd
# Clone git repo
git clone https://github.com/GramThanos/FIDO2-Demo-App.git
# Enter folder
cd FIDO2-Demo-App
```

Initialize the dependencies of the app, re-build database and insert test user (username: test, password: test)

```cmd
# Initialize app dependencies
sudo bundle install
sudo yarn install

# Rebuild database
rake db:drop && rake db:create && rake db:migrate

# Add test user
echo 'User.create!(name: "test", email: "test@test.com", password: "test", password_confirmation: "test")' | bundle exec rails c
```

Configure application for localhost usage. WebAuthn works on localhost, you will need to have a FIDO2 or FIDO U2F authenticator on the host machine.

```cmd
# Change configuration
cp config/initializers/webauthn.rb config/initializers/webauthn.rb.back
echo -e 'WebAuthn.configure do |config|\n\tconfig.origin = "https://localhost:3000"\n\tconfig.rp_name = "FIDO2"\nend' > config/initializers/webauthn.rb

# Start server
sudo rails s -b 0.0.0.0 -p 3000
```

#### Deploying

To deploy the application and test it to your phone, you will need to set it up on a server with a domain and an SSL certificate, due to the fact that WebAuthn only works under HTTPS and an domain.

Also, you can create a self singed certificate but still, the application will have to be served from a domain. At the commands below, change the `your.domain.com` to your domain name.

```cmd
# Change configuration
echo -e 'WebAuthn.configure do |config|\n\tconfig.origin = "https://your.domain.com:3000"\n\tconfig.rp_name = "FIDO2"\nend' > config/initializers/webauthn.rb

# OpenSSL
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt -subj "/C=GR/ST=Athens/L=Athens/O=University of Piraeus/OU=Department of Digital Systems/CN=*"

# Start server
sudo rails s -b 'ssl://0.0.0.0:3000?key=localhost.key&cert=localhost.crt'
```

#### Other info

You can delete the test user by running
`echo 'User.delete_by(email: "test@test.com")' | bundle exec rails c`.

You can use an Apache web server as a proxy to serve the web application and handle both the domain and the SSL certificate.

Here is an example configuration of Apache with a Let's Encrypt certificate that proxies the requests to the server that runs the FIDO application. (change the `example.domain.com` to your domain and the `192.168.99.99` to the application server's IP).
```config
<IfModule mod_ssl.c>
<VirtualHost *:443>

	ServerAdmin mail@email.com
	ServerName example.domain.com
	DocumentRoot /var/www/example.domain.com/public_html

	# LogLevel warn
	ErrorLog /var/www/example.domain.com/error.log
	CustomLog /var/www/example.domain.com/access.log combined

	# Proxy pass
	ProxyPreserveHost On
	SSLProxyEngine on
	RequestHeader set X_FORWARDED_PROTO 'https'
	ProxyPassReverseCookieDomain "192.168.99.99" "example.domain.com"
	# Exclude paths
	ProxyPass /.well-known/ !
	# Proxy
	ProxyPass / http://192.168.99.99:3000/
	ProxyPassReverse / http://192.168.99.99:3000/

	# SSL
	SSLCertificateFile /etc/letsencrypt/live/example.domain.com/fullchain.pem
	SSLCertificateKeyFile /etc/letsencrypt/live/example.domain.com/privkey.pem
	Include /etc/letsencrypt/options-ssl-apache.conf

</VirtualHost>
</IfModule>
```

___


### License

This project is under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).

___

### About

This web page was developed as part of the FIDO Project during the postgraduate program "Digital Systems Security"

*University of Piraeus*, *Department of Digital Systems*, *Digital Systems Security*

Authors: *Kostas Sarikioses*, *Dimitris Georgilakis*, *Athanasios Vasileios Grammatopoulos*
