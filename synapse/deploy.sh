sudo docker stop synapse
sudo docker rm synapse

git pull

sudo docker build -t synapse . --network="host"

sudo docker run --name synapse --network="host" -d  synapse

