<?php

define("BX_SECURITY_SESSION_VIRTUAL", true);

$start = microtime(true);

require $_SERVER["DOCUMENT_ROOT"] . "/bitrix/modules/main/include/prolog_before.php";

$end = microtime(true);

echo "Time: " . ($end - $start);
