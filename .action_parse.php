<?php

if (empty($_SERVER['argv'][1])) {
	exit(1);
}
$fname = $_SERVER['argv'][1];
if (!file_exists($fname)) {
	exit(2);
}
$fdestname = $fname.'.tokenstmp';
if (file_exists($fdestname)) {
	unlink($fdestname);
}
$fout = fopen($fdestname, 'w');
if (!$fout) {
	exit(3);
}
foreach (token_get_all(file_get_contents($fname)) as $t) {
	if (is_array($t)) {
		$t[0] = token_name($t[0]);
	} else {
		$t = ['', $t, ''];
	}
	fputcsv($fout, $t);
}
fclose($fout);
