<?php

error_reporting(E_ALL ^ E_NOTICE);
ini_set('dislay_errors', 'on');

// Bitrix defines
define('LANGUAGE_ID', 'ru');
define('SITE_CHARSET', 'UTF-8');
define('LANG_CHARSET', 'UTF-8');

if (empty($_SERVER['DOCUMENT_ROOT'])) {
	$_SERVER['DOCUMENT_ROOT'] = dirname(dirname(__DIR__));
}

// fake functions

function nop__spl_autoload_register($autoload_function, $throw = true, $prepend = false)
{
}
