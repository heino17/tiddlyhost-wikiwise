## Anpassungen für Tiddlyhost-wikiwise

### ports (docker-compose.yml)
Auf meinem Server läuft ein Webserver auf port 80,
deshalb bekommt Tiddlyhost-wikiwise port 8034 bzw. 7443
In der docker-compose.yml sieht's dann so aus:
```
ports:
    - "8034:80"
    - "7443:443"
```
### nginx.conf

Falls eine leere nginx.conf erstellt wird, hier eine Vorlage
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
