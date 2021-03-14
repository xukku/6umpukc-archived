<?php

$start = microtime(true);

echo "<pre>";

$totalNum = 0;
$baseDir = $_SERVER["DOCUMENT_ROOT"];
$it = new \RecursiveIteratorIterator(
	new \RecursiveDirectoryIterator(
		$baseDir,
		\RecursiveDirectoryIterator::SKIP_DOTS
	)
);
$l = strlen($baseDir) + 1;
foreach ($it as $f) {
	$totalNum++;
	$name = $f->getPathname();
	$path = substr($name, $l);
	if (!$f->isFile()) {
		continue;
	}
	echo $path . "\n";
}

echo "\n---\nTOTAL: $totalNum\n";

$end = microtime(true);

echo "\n\nTime: " . ($end - $start);
