<?php

//TODO!!! передавать DOCUMENT_ROOT сайта в параметрах
$_SERVER['DOCUMENT_ROOT'] = $_SERVER['argv'][1];

require $_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/cli/bootstrap.php';

//TODO!!! тут код для очистки установленного на сайте решения
