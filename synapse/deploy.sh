sudo docker stop synapse || true
sudo docker rm synapse || true

git pull

sudo docker build -t synapse . --network="host"

sudo docker run --name synapse --network="host" -d synapse