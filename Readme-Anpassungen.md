## Anpassungen für Tiddlyhost-wikiwise

### ports (docker-compose.yml)
Auf meinem Server läuft ein Webserver auf port 80,
deshalb bekommt Tiddlyhost-wikiwise port 8034 bzw. 7443
In der docker-compose.yml sieht's dann so aus:
ports:
    - "8034:80"
    - "7443:443"

###     
