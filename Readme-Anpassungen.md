## Anpassungen für Tiddlyhost-wikiwise

### make rails-init
Falls es eine Fehlermeldung wegen jsMath-3.3g.zip, Error 23 gibt, fehlt der Ordner "etc" im Hauptverzeichnis tiddlyhost-com
```
Verzeichnis anlegen 
mkdir etc
Verzeichnisrechte
sudo chown -R deinuser:deinuser etc
```
dann make rails-init wiederholen

### make test
Wird 4  404-Fehler zeigen, ich habe in der '/rails/lib/settings/features.rb' 
'subscriptions_enabled' auf 'false' gesetzt.
Damit ist die Abonnement-Funktion im Adminbereich deaktiviert.

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

Falls eine leere nginx.conf erstellt wurde, hier eine Vorlage die bei mir läuft.  
Server "listen" bleibt hier auf 80!
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

### Impressum - Seite
/rails/app/views/home/impressum.html.haml
Als kleine Spielerei ist Adresse und eMail-Adresse in Unicode codiert,
so stehen die Daten nicht im Quelltext...
 
https://iotools.cloud/tool/text-to-unicode-converter/

### apache2 tiddlyhost.local host Beispiel
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
