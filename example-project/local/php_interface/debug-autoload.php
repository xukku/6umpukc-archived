<?php

// collect class dependencies
spl_autoload_register(function ($className) {
	file_put_contents(
		dirname(dirname(__DIR__)) . '/vendor/.deps.log',
		$className . "\n",
		FILE_APPEND | LOCK_EX
	);
	return false;
}, true, true);
