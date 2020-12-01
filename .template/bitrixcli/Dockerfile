
# install docker:
#	sudo snap install docker
#	usermod -aG docker "${USER}"
#	newgrp docker

# build:
#	docker build -t bitrixcli .

# run:
#	docker run bitrixcli /home/node/node_modules/.bin/bitrix --help

# remove:
#	docker rmi bitrixcli --force

FROM node:9.11.2

WORKDIR /home/node

RUN npm install @bitrix/cli

CMD ["/home/node/node_modules/.bin/bitrix", "--help"]
