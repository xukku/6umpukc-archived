
# Тулинг для разработчиков решений на Bitrix

## Как установить

`git clone https://github.com/6umpukc-uHKBu3umop/6umpukc.git ~/bin/6umpukc/ && cd ~/bin/6umpukc/ && chmod +x bx && ./bx self-install`

для Windows запускать в командной строке Git Bash https://gitforwindows.org/ или http://www.msys2.org/

## Сконвертировать текущую папку модуля, компонента, шаблона и т.п.

В utf-8

`bx conv-utf`

В windows-1251

`bx conv-win`

## Создать полную версию модуля .last_version.tar.gz

`bx mod-pack`

## Скачать модули решения из указанных репозитариев в .env

`bx solution-init`

## Сбросить данные установленного решения указанного в .env

`bx solution-reset`

## Транспиляция/минификация javascript-файлов

Установить google-closure-compiler (https://github.com/google/closure-compiler)

`bx es9-install`

Преобразовать `*.es9.js` файлы в `*.min.js` от текущей директории

`bx es9`

Преобразовать в проекте/сайте

`bx es9 all`

## Скачать скрипт инсталятора bitrixsetup.php

`bx fetch setup`

## Стандартные редакции

`bx fetch` или `bx fetch start`

`bx fetch business`

`bx fetch crm`

## Минимизированное ядро

Часть модулей/компонентов убрана, при этом будет рабочая Bitrix панель и шаблоны.

Данная сборка после установки уместится в лимиты на количество файлов бесплатного хостинга Beget - https://beget.com/ru/free-hosting

`bx fetch core`

Скачать готовую сборку можно тут - https://bitbucket.org/6umpukc/6umpukc/get/master.zip

## "Микроядро"

Оставлены только классы модулей - чтобы пилить свой микрофреймворк, переиспользуя кодовую базу Bitrix D7.

`bx fetch micro`

Скачать готовую сборку можно тут - https://bitbucket.org/6umpukc/microframework/get/master.zip

### Cборка на основе полученного списка классов и файлов

Для сопоставления классов и файлов используются данные автозагрузки composer

```
composer -o dump-autoload
bx build
```
или `bx rebuild`

### Создать одно-файловое приложение [если хочешь удивить коллег или друзей bitrix-кодом или sympony в одном файле]
```
composer -o dump-autoload
bx build onefile
```
или `bx rebuild onefile`

### Пример структуры проекта

https://bitbucket.org/6umpukc/microframework/
