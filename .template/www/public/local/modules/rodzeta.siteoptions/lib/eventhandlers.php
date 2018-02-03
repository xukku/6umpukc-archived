<?php

namespace Rodzeta\Siteoptions;

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) die();

class EventHandlers
{
    public static function register()
    {
        //NOTE здесь регистрация обработчиков https://dev.1c-bitrix.ru/api_help/main/events/index.php
        // обработчики лучше вынести в отдельные классы по смыслу - например
        // \Rodzeta\Siteoptions\EmailToBitrix24::register(); // обработка почтовых событий - отправка лидов в Bitrix24
        // \Rodzeta\Siteoptions\IblockToBitrix24::register(); // обработка изменений инфоблока - синхронизация с товарами Bitrix24
    }
}
