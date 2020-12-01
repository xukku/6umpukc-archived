
# install docker:
#	sudo snap install docker
#	usermod -aG docker "${USER}"
#	newgrp docker

# build:
#	docker build -t bitrixcli .

# run:
#	docker run --volume="$PWD:/home/node/work" bitrixcli bitrix --help
#	docker run --volume="$PWD:/home/node/work" bitrixcli bitrix build --path /home/node/work

# remove:
#	docker rmi bitrixcli --force

FROM node:9.11.2

WORKDIR /home/node

RUN mkdir work && npm install --unsafe-perm -g @bitrix/cli

CMD ["bitrix", "--help"]
