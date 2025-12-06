## Anpassungen für Tiddlyhost-wikiwise

### make rails-init
Falls es eine Fehlermeldung wegen jsMath-3.3g.zip, Error 23 gibt, fehlt der Ordner "etc" im Hauptverzeichnis tiddlyhost-com
Verzeichnis anlegen 
mkdir etc
Verzeichnisrechte
sudo chown -R deinuser:deinuser etc

dann make rails-init wiederholen

### ports (docker-compose.yml)
Auf meinem Server läuft ein apache2-Webserver auf port 80 bzw. 443,
deshalb bekommt Tiddlyhost-wikiwise port 8034 bzw. 7443 und wird per apache auf port 8034 geleitet.
In der docker-compose.yml sieht es so aus:
```
ports:
    - "8034:80"
    - "7443:443"
```
### leere /docker/nginx-conf/nginx.conf

Falls eine leere nginx.conf erstellt wurde, hier eine Vorlage die bei mir läuft
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
