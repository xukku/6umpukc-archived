
# install docker (on Unbuntu):
#	sudo snap install docker
#	sudo addgroup --system docker
#	sudo adduser $USER docker
#	newgrp docker
#	sudo snap enable docker

# remove:
#	docker rmi bitrixcli --force

# build:
#	docker build -t bitrixcli .

# run (!если есть зависимости - будет собирать некорректно):
#	docker run --volume="$PWD:/home/node" bitrixcli
#	docker run --volume="$PWD:/home/node" bitrixcli bitrix build --path /home/node
#
#	docker run -it --volume="$PWD:/home/node" bitrixcli bitrix create
#
#	docker run bitrixcli bitrix --help

# !для сборки с зависимостями должна быть соблюдена структура bitrix-сайта и расположение js-кода в local:
#	- если код находится в bitrix - пробрасываем в контейнер папку bitrix как local
#	- запускаем сборку в папке local/js/..., а не в папке модуля
#	docker run --volume="/home/bitrix/ext_www/s01.r.citrus-dev.ru/bitrix:/home/node/local" bitrixcli bitrix build --path /home/node/local/js/citrus/asan24/crmselector
#	docker run --volume="/home/bitrix/ext_www/s01.r.citrus-dev.ru/local:/home/node/local" bitrixcli bitrix build --path /home/node/local/js/citrus/asan24/crmselector

FROM node:9.11.2

WORKDIR /home/node

RUN npm install --unsafe-perm -g @bitrix/cli

CMD ["bitrix", "build"]
