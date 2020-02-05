
- для Windows запускать в командной строке Git Bash https://gitforwindows.org/ или http://www.msys2.org/

- пример приложения на "микрофреймворке"

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
