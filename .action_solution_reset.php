<?php

define('BX_BUFFER_USED', true);

$_SERVER['DOCUMENT_ROOT'] = $_SERVER['argv'][1];

require $_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/cli/bootstrap.php';

function FixPath($path)
{
	return str_replace(DIRECTORY_SEPARATOR, '/', $path);
}

function Action_clear_site($basePath)
{
	$excludedDirs = [
		'bitrix' => 1,
		'local' => 1,
		'upload' => 1,
		'.vscode' => 1,
		'.idea' => 1,
	];
	$excludedFiles = [
		'.access.php' => 1,
		'.htaccess' => 1,
		'.env' => 1,
		'deploy.sh' => 1,
		'deploydb.sh' => 1,
		'health.php' => 1,
	];
	$excludedExtensions = [
		'sublime-project' => 1,
		'sublime-workspace' => 1,
	];
	echo "Cleanup site files\n";
	$it = new \DirectoryIterator($basePath);
	foreach ($it as $f)
	{
		$name = $f->getPathname();
		if ($f->isDir())
		{
			if (!$f->isDot() && !isset($excludedDirs[$f->getBasename()]))
			{
				echo "\tremove " . $name . " ...\n";
				system('rm -Rf ' . $name);
			}
		}
		elseif ($f->isFile())
		{
			if (!isset($excludedFiles[$f->getBasename()]))
			{
				if (!isset($excludedExtensions[pathinfo($f->getBasename(), PATHINFO_EXTENSION)]))
				{
					echo "\tremove " . $name . "\n";
					unlink($name);
				}
			}
		}
	}
}

function Action_clear_files($basePath)
{
	$dirs = [
		'bitrix/wizards',
		'bitrix/components',
		'bitrix/templates',
	];
	foreach ($dirs as $dir)
	{
		$path = FixPath($basePath . DIRECTORY_SEPARATOR . $dir);
		if (!is_dir($path))
		{
			continue;
		}
		echo 'Cleanup ' . $path . " ...\n";
		$it = new \DirectoryIterator($path);
		foreach ($it as $f)
		{
			$name = $f->getPathname();
			if (!$f->isDir() || $f->isDot() || basename($name) == '.default')
			{
				continue;
			}
			if (basename($path) != 'wizards' && basename($name) == 'bitrix')
			{
				continue;
			}
			echo "\tremove " . $name . " ...\n";
			system('rm -Rf ' . $name);
		}
	}
}

function Action_clear_iblock($basePath)
{
	echo "Remove iblocks\n";
	\CModule::IncludeModule('iblock');
	$res = \CIBlock::GetList([], ['CHECK_PERMISSIONS' => 'N'], true);
	while ($row = $res->Fetch())
	{
		echo "\t" . $row['ID'] . ' - ' . $row['CODE'] . "...\n";
		\CIBlock::Delete($row['ID']);
	}
	echo "Remove iblock types\n";
	$res = \CIBlockType::GetList();
	while ($row = $res->Fetch())
	{
		echo "\t" . $row['ID'] . "...\n";
		\CIBlockType::Delete($row['ID']);
	}
}

function Action_clear_cache($basePath)
{
	echo "Clear cache...\n";
	BXClearCache(true);

	if (class_exists('\Bitrix\Main\Data\StaticHtmlCache'))
	{
		echo "Clear static html cache...\n";
		\Bitrix\Main\Data\StaticHtmlCache::getInstance()->deleteAll();
	}
	if (class_exists('\Bitrix\Main\Data\ManagedCache'))
	{
		echo "Clear managed cache...\n";
		$cache = new \Bitrix\Main\Data\ManagedCache();
		$cache->cleanAll();
	}
	if (class_exists('\CStackCacheManager'))
	{
		echo "Clear stack cache...\n";
		$cache = new \CStackCacheManager();
		$cache->CleanAll();
	}
	if (method_exists('\CHTMLPagesCache', 'CleanAll'))
	{
		echo "Clear htmlpages cache...\n";
		\CHTMLPagesCache::CleanAll();
	}
}

$basePath = $_SERVER['DOCUMENT_ROOT'];

Action_clear_site($basePath);
Action_clear_files($basePath);
Action_clear_iblock($basePath);
Action_clear_cache($basePath);

if (!empty($_SERVER['SOLUTION_MAIL_EVENT_PREFIX']))
{
	$emailTypePrefixes = array_filter(array_map('trim', explode("\n", trim($_SERVER['SOLUTION_MAIL_EVENT_PREFIX']))));
	echo "Remove email templates\n";
	// remove solution email templates and types
	$emsg = new \CEventMessage();
	$res = \CEventMessage::GetList($by = 'id', $order = 'desc', $arFilter = []);
	while ($row = $res->GetNext())
	{
		foreach ($emailTypePrefixes as $emailTypePrefix)
		{
			if ($emailTypePrefix == substr($row['EVENT_NAME'], 0, strlen($emailTypePrefix)))
			{
				echo "\t" . $row['ID'] . ' - ' . $row['EVENT_NAME'] . "...\n";
				$emsg->Delete($row['ID']);
			}
		}
	}
	echo "Remove email types\n";
	$et = new \CEventType();
	$res = \CEventType::GetList();
	while ($row = $res->Fetch())
	{
		foreach ($emailTypePrefixes as $emailTypePrefix)
		{
			if ($emailTypePrefix == substr($row['EVENT_NAME'], 0, strlen($emailTypePrefix)))
			{
				echo "\t" . $row['ID'] . ' - ' . $row['EVENT_NAME'] . "...\n";
				$et->Delete($row['EVENT_NAME']);
			}
		}
	}
}

if (!empty($_SERVER['SOLUTION_DB_PREFIX']))
{
	$dbTablePrefixes = array_filter(array_map('trim', explode("\n", trim($_SERVER['SOLUTION_DB_PREFIX']))));
	echo "Remove database tables\n";
	$connection = \Bitrix\Main\Application::getConnection();
	$sqlHelper = $connection->getSqlHelper();
	foreach ($connection->query('show tables from ' . $sqlHelper->forSql($connection->getDatabase())) as $row)
	{
		$tableName = current($row);
		foreach ($dbTablePrefixes as $dbTablePrefix)
		{
			if ($dbTablePrefix == substr($tableName, 0, strlen($dbTablePrefix)))
			{
				echo "\t" . $tableName . "...\n";
				$connection->dropTable($tableName);
			}
		}
	}
}
