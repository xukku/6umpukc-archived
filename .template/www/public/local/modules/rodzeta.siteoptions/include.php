<?php

namespace Rodzeta\Siteoptions;

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) die();

function init()
{
    EventHandlers::register();
}

init();
