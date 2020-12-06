
# install docker (on Unbuntu):
#	snap install docker
#	addgroup --system docker
#	adduser $USER docker
#	newgrp docker
#	snap enable docker

# remove:
#	docker rmi bitrixcli --force

# build:
#	docker build -t bitrixcli .

# run:
#	docker run --volume="$PWD:/home/node" bitrixcli
#	docker run --volume="$PWD:/home/node" bitrixcli bitrix build --path /home/node
#
#	docker run -it --volume="$PWD:/home/node" bitrixcli bitrix create
#
#	docker run bitrixcli bitrix --help

FROM node:9.11.2

WORKDIR /home/node

RUN npm install --unsafe-perm -g @bitrix/cli

CMD ["bitrix", "build"]
