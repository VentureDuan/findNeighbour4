# Installing mongodb
We have tested this application with  Mongo 4.02 and 4.4 (linux, and using Mongo Atlas, a cloud installation).

We tested the following:
- we ran a single mongodb instance on the same high-ram machine as the server, which is not the recommended regime for resilience
- we stored SARS-CoV-2 genomes and their relationships in the server
- we stress tested to up to 500k samples.  For larger scale testing, we used a cloud relational databases.

## Remote server
If you are using a remote mongodb server, you do not need to install mongodb locally.  We have tested findNeighbour4 with [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).

## Docker (Recommended)
Using Docker Compose is the easiest way to run MongoDB 4.4 without installing it directly on your system.

### Prerequisites
- Docker installed
- Docker Compose installed

### Installation Steps
1. Navigate to the project root directory where `docker-compose.yml` is located
2. Start MongoDB:
```bash
docker-compose up -d
```

3. Check if MongoDB is running:
```bash
docker-compose ps
```

4. View logs:
```bash
docker-compose logs mongodb
```

### Managing the MongoDB Container
- Stop MongoDB:
```bash
docker-compose stop
```

- Start MongoDB:
```bash
docker-compose start
```

- Restart MongoDB:
```bash
docker-compose restart
```

- Stop and remove the container (data will be preserved in volumes):
```bash
docker-compose down
```

- Stop and remove the container and volumes (⚠️ this will delete all data):
```bash
docker-compose down -v
```

### Connection String
The default connection string for findNeighbour4 configuration is:
```
mongodb://127.0.0.1
```

MongoDB will be accessible on `localhost:27017`. The data is persisted in Docker volumes, so it will survive container restarts.

## Linux
Please follow read the [documentation](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/).


### Recipe
The install steps will vary by linux and Mongo version, see above. The below installs MongoDB 4 on Ubuntu 16.04 LTS:
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt update
sudo apt install mongodb-org
```

It is automatically started but can be started with
```
sudo systemctl enable mongod
sudo systemctl start mongod
```

It can be stopped/restarted with
```
sudo systemctl stop mongod
sudo systemctl restart mongod
```  

If a sharded cluster is considered necessary, please see [here](mongosharding.md).
Note that the default installation is accessible without authentication to everyone with access to the machine,   
but the mongo server has to be explicitly bound to an external IP for it to be accessible outside the machine it is running on.

