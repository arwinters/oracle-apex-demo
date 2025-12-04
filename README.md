# Oracle APEX Demo

Oracle APEX 24.2 met Oracle XE 21.3.0 en ORDS in Docker Compose.

## Vereisten

- Docker Desktop (macOS/Windows) of Docker + Docker Compose (Linux/WSL2)  
- Minimaal ~8GB RAM beschikbaar voor de containers  
- WSL2 Ubuntu 24.04 (voor Windows-gebruikers)

> Op macOS en op native Linux werkt deze setup out-of-the-box (OOB) met de standaard permissies en volumes. Alleen in WSL2 kunnen er permission-issues optreden door volume mounts; zie Setup voor WSL2-stappen.

## Setup

### 1. Clone repository
Zorg dat je in je projectmap bent:
```bash
git clone https://github.com/arwinters/oracle-apex-demo.git
cd ./oracle-apex-demo
mkdir ./logs ./config ./apex ./ords_config ./ords_logs
```

### 2. (Alleen WSL2) Maak directories aan en stel eigenaar in
Als je op WSL2 werkt en je gebruikt host-volume mounts, stel dan eigenaar in op de UID van de `oracle` user in de container (voorbeeld UID is 54321):

1) Vind de UID (éénmalig):
```bash
docker run --rm container-registry.oracle.com/database/express:21.3.0-xe id oracle
# voorbeeld output: uid=54321(oracle) gid=54321(oinstall) ...
```

2) Pas eigenaar en permissies aan op je host via WSL 2:
```bash
sudo chown -R 54321:54321 ./logs ./scripts ./config ./apex ./ords_config ./ords_logs
sudo chmod -R 755 ./logs ./scripts ./config ./apex ./ords_config ./ords_logs
```

Op macOS / native Linux is dit niet nodig.

### 3. (Optioneel) Gebruik je custom image
Als je APEX vooraf in de image wilt hebben, uncomment de `build:` sectie in `docker-compose.yml` en comment de `image:` regel uit. Dit geeft je controle over owners/permissions in de image zelf.

### 4. Build en start containers (aanbevolen commando's)

- Build (forceer rebuild):
```bash
docker compose build --no-cache
```

- Start in foreground:
```bash
docker compose up
```

- Start in background (detached):
```bash
docker compose up -d
```

- Stop en verwijder containers:
```bash
docker compose down
```

- Stop, verwijder containers en volumes:
```bash
docker compose down -v
```

### 5. Logs en health
- Follow logs van de database:
```bash
docker compose logs -f oracle-db
```

- Follow logs van ORDS:
```bash
docker compose logs -f ords
```

Healthcheck is ingesteld in `docker-compose.yml`. Startup kan enkele minuten duren (APEX installatie).

## Toegang

- Oracle Database: localhost:1521
  - Wachtwoord: zie `docker-compose.yml`

- APEX: http://localhost:8181/apex  
- ORDS: http://localhost:8181/ords

## Troubleshooting

- Permission denied bij schrijven naar `/opt/oracle/logs`:
  - Controleer of de host-mount `./logs` bestaat en eigendom heeft van de container `oracle` UID (zie stappen hierboven).
  - Indien je custom image bouwt: zorg dat Dockerfile `/opt/oracle/logs` met correcte owner/perms aanmaakt voordat `USER oracle` wordt ingesteld.

- Container stopt vroegtijdig:
  - Bekijk logs: `docker compose logs -f oracle-db`
  - Controleer healthcheck-status: `docker compose ps`

- Als je veel WSL2-permission problemen ervaart en je wilt snel verder, overweeg tijdelijk de `./logs` mount weg te laten zodat de container zijn interne logs gebruikt (niet persistent).

## Projectstructuur

```
oracle-apex-demo/
├── Dockerfile
├── docker-compose.yml
├── scripts/
│   ├── db-entrypoint-wrapper.sh
│   ├── install_apex.sh
│   ├── enable_rest.sh
│   └── start_ords.sh
├── config/
│   └── config.env
├── apex/
├── logs/
├── ords_config/
├── ords_logs/
└── README.md
```

## Opmerkingen

- Data wordt bewaard in het Docker volume `oracle_data` (gedefinieerd in docker-compose.yml).  
- Voor productie altijd wachtwoorden en gevoelige data veilig beheren (niet in plain `docker-compose.yml`).  
- Gebruik de custom Dockerfile als je volledige controle wil over owners/permissions en APEX-installatie vooraf wilt integreren.
