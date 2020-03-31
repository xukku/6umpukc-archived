<?php

$basePath = getcwd();
$fname = $basePath . '/install/version.php';
require $fname;

$arModuleVersion['VERSION_DATE'] = date('Y-m-d H:i:s');
$version = explode('.', trim($arModuleVersion['VERSION']));
$v = (int)array_pop($version) + 1;
$version[] = $v;
$strVersion = implode('.', $version);
$arModuleVersion['VERSION'] = $strVersion;

file_put_contents($fname, '<' . '?php
$arModuleVersion = array(
	"VERSION" => "' . $strVersion . '",
	"VERSION_DATE" => "' . $arModuleVersion['VERSION_DATE'] . '",
);');

system('git commit -am "Номер версии"');
system('git tag ' . $strVersion);
system('git push origin ' . $strVersion);
system('git push');

if (!empty($_SERVER['argv'][1]))
{
	system('xdg-open "' . $_SERVER['argv'][1] . '"');
}
