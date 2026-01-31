## German part
scroll down gor english part

# Anpassungen für Tiddlyhost-wikiwise
- Das ist im Grunde das woran ich denken muss, um tiddlyhost.local im Browser aufrufen zu können.

## Das Einzige Änderung die wichtig ist zu beachten ist folgende:
### ports (docker-compose.yml)
Auf meinem Server läuft ein apache2-Webserver auf port 80 bzw. 443,
deshalb bekommt Tiddlyhost-wikiwise port 8034 bzw. 7443 und wird per apache auf port 8034 geleitet.
In der docker-compose.yml sieht es so aus:
- Das brauch ich so
```
ports:
    - "8034:80"
    - "7443:443"
```
Original ist:
```
ports:
    - "80:80"
    - "443:443"
```

## Ab hier sind's nur Erinnerungshilfen für mich...

### make rails-init
Falls es eine Fehlermeldung wegen jsMath-3.3g.zip, Error 23 gibt, fehlt der Ordner "etc" im Hauptverzeichnis tiddlyhost-com
```
Verzeichnis anlegen 
mkdir etc
Verzeichnisrechte
sudo chown -R deinuser:deinuser etc
```
dann make rails-init wiederholen


### leere /docker/nginx-conf/nginx.conf
- Falls eine leere nginx.conf erstellt wurde, hier eine Vorlage für meinen Schnellstart.
- Server "listen" bleibt hier auf 80!
```
events {
    worker_connections 1024;
}

http {
    upstream app {
        server th_app:3333;
    }

    server {
        listen 80;
        server_name tiddlyhost.local *.tiddlyhost.local;
            client_max_body_size 100M;

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /cable {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

### evtl. /docker/config/settings_local.yml anpassen
```
HOSTNAME: tiddlyhost.local
LETSENCRYPT_EMAIL: dev@example.com
RAILS_ENV: development
SSL_MODE: self_signed
```

### apache2 tiddlyhost.local host

```
<VirtualHost 192.168.17.17:80>
    ServerName tiddlyhost.local
    ServerAlias *.tiddlyhost.local  # Für Wildcard-Subdomains
    Redirect permanent / https://tiddlyhost.local/
</VirtualHost>
<VirtualHost 192.168.17.17:443> 
    ServerName tiddlyhost.local
    ServerAlias *.tiddlyhost.local  # Für Wildcard-Subdomains

    ProxyRequests Off
    ProxyPreserveHost On
    #ProxyVia Full

    <Proxy *>
        Require all granted
    </Proxy>

    ProxyPass / http://127.0.0.1:8034/
    ProxyPassReverse / http://127.0.0.1:8034/
    AllowEncodedSlashes On
    SSLEngine on
    SSLCertificateFile /pfad/zum/letsencrypt-cert.pem
    SSLCertificateKeyFile /pfad/zum/letsencrypt-key.pem
    SSLCACertificateFile /pfad/zum/letsencrypt-ca.pem
    SSLProtocol +TLSv1.2 +TLSv1.3   
</VirtualHost>  
```


### Impressum - Seite (speziell für die Darstellung in Europa)
- Die Impressum-Seite gibt es in diesem Branch nicht, hier nur zu meiner Erinnerung
/rails/app/views/home/impressum.html.haml
Als kleine Spielerei sind die Adresse und die E-Mail-Adresse in Unicode verschlüsselt,
sodass Datensammler die Daten nur als Zahlen und nicht als Klartext lesen können...
 
https://iotools.cloud/tool/text-to-unicode-converter/


## English part

# Adjustments for Tiddlyhost-wikiwise
- This is basically what I have to think about in order to be able to access tiddlyhost.local in my browser.

## The only change that is important to consider is the following:
### ports (docker-compose.yml)
On my server, an apache2 web server runs on port 80 or 443,
therefore, Tiddlyhost-wikiwise is port 8034 or 7443 and is routed via apache to port 8034.
In the docker-compose.yml it looks like this:
- I need it that way
```
ports:
    - "8034:80"
    - "7443:443"
```
Original is:
```
ports:
    - "80:80"
    - "443:443"
```

## From here it's just reminders for me...

### make rails-init
If there is an error message due to jsMath-3.3g.zip, Error 23, the folder "etc" is missing in the main directory tiddlyhost-com
```
Create a directory 
mkdir etc
Directory rights
sudo chown -R deinuser:deinuser etc
```
then repeat 'make rails-init'


### empty /docker/nginx-conf/nginx.conf
- If an empty nginx.conf was created, here is a template for my quick start.
- Server "list" stays here on 80!
```
events {
    worker_connections 1024;
}

http {
    upstream app {
        server th_app:3333;
    }

    server {
        listen 80;
        server_name tiddlyhost.local *.tiddlyhost.local;
            client_max_body_size 100M;

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /cable {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

### possibly /docker/config/settings_local.yml customize
```
HOSTNAME: tiddlyhost.local
LETSENCRYPT_EMAIL: dev@example.com
RAILS_ENV: development
SSL_MODE: self_signed
```

### apache2 tiddlyhost.local host

```
<VirtualHost 192.168.17.17:80>
    ServerName tiddlyhost.local
    ServerAlias *.tiddlyhost.local  # Für Wildcard-Subdomains
    Redirect permanent / https://tiddlyhost.local/
</VirtualHost>
<VirtualHost 192.168.17.17:443> 
    ServerName tiddlyhost.local
    ServerAlias *.tiddlyhost.local  # Für Wildcard-Subdomains

    ProxyRequests Off
    ProxyPreserveHost On
    #ProxyVia Full

    <Proxy *>
        Require all granted
    </Proxy>

    ProxyPass / http://127.0.0.1:8034/
    ProxyPassReverse / http://127.0.0.1:8034/
    AllowEncodedSlashes On
    SSLEngine on
    SSLCertificateFile /pfad/zum/letsencrypt-cert.pem
    SSLCertificateKeyFile /pfad/zum/letsencrypt-key.pem
    SSLCACertificateFile /pfad/zum/letsencrypt-ca.pem
    SSLProtocol +TLSv1.2 +TLSv1.3   
</VirtualHost>  
```


### Imprint - page (especially for presentation in Europe)
- The imprint page does not exist in this branch, here only for my memory
/rails/app/views/home/impressum.html.haml
As a small gimmick, the address and email address is encoded in Unicode,
so data collectors read the data only as numbers, not plain text...
 
https://iotools.cloud/tool/text-to-unicode-converter/