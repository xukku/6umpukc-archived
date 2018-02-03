<?php

if (empty($_SERVER['argv'][1]))
{
	exit(1);
}

function HandleConvUtfFileAction($name)
{
	$content = file_get_contents($name);
	if (mb_detect_encoding($content, 'UTF-8', true))
	{
		return;
	}
	$content = mb_convert_encoding($content, 'utf-8', 'windows-1251');
	file_put_contents($name, $content);
}

function HandleConvUtfAction()
{
	$basePath = getcwd();
	$it = new \RecursiveIteratorIterator(
		new \RecursiveDirectoryIterator(
			$basePath,
			\RecursiveDirectoryIterator::SKIP_DOTS
		),
		\RecursiveIteratorIterator::SELF_FIRST
	);
	foreach ($it as $f)
	{
		$name = $f->getPathname();
		if (strpos($name, '.git') !== false
				|| strpos($name, '.dev') !== false
				|| strpos($name, '/xml/ru/') !== false
				|| strpos($name, 'vendor') !== false)
		{
			continue;
		}
		if ($f->isDir())
		{
			//echo "processing $name ...\n";
			continue;
		}
		if (!$f->isFile())
		{
			continue;
		}
		$ext = $f->getExtension();
		if ($ext != 'php' && $ext != 'xml' && $ext != 'json')
		{
			continue;
		}
		$content = file_get_contents($name);
		if (mb_detect_encoding($content, 'UTF-8', true))
		{
			// utf
			continue;
		}
		echo $name . "\n";
		$content = mb_convert_encoding($content, 'utf-8', 'windows-1251');
		file_put_contents($name, $content);
	}
}

function HandleConvWinAction()
{
	$basePath = getcwd();
	$it = new \RecursiveIteratorIterator(
		new \RecursiveDirectoryIterator(
			$basePath,
			\RecursiveDirectoryIterator::SKIP_DOTS
		),
		\RecursiveIteratorIterator::SELF_FIRST
	);
	foreach ($it as $f)
	{
		$name = $f->getPathname();
		if (strpos($name, '.git') !== false
				|| strpos($name, '.dev') !== false
				|| strpos($name, '/xml/ru/') !== false
				|| strpos($name, 'vendor') !== false)
		{
			continue;
		}
		if ($f->isDir())
		{
			//echo "processing $name ...\n";
			continue;
		}
		if (!$f->isFile())
		{
			continue;
		}
		$ext = $f->getExtension();
		if ($ext != 'php' && $ext != 'xml' && $ext != 'json')
		{
			continue;
		}
		$content = file_get_contents($name);
		if (!mb_detect_encoding($content, 'UTF-8', true))
		{
			// not utf
			continue;
		}
		echo $name . "\n";
		$content = mb_convert_encoding($content, 'windows-1251', 'utf-8');
		file_put_contents($name, $content);
	}
}

function HandleModPackAction()
{
	$ignoredDirs = [
		'.dev/',
		'.git/',
		'.idea',
		'.last_version/',
		'out/',
		'src/',
	];
	$ignoredExtensions = [
		'code-workspace' => 1,
		'exe' => 1,
		'jar' => 1,
		'gitignore' => 1,
		'hxml' => 1,
		'iml' => 1,
		'sublime-project' => 1,
		'sublime-workspace' => 1,
	];
	$ignoredFiles = [
		'composer.json' => 1,
		'composer.lock' => 1,
	];
	$currentPath = getcwd();
	$dest = '.last_version.tar.gz';
	$tmpFolder = '.last_version';
	foreach ($ignoredDirs as $i => $dir)
	{
		$ignoredDirs[$i] = str_replace('/', DIRECTORY_SEPARATOR, $dir);
	}
	// clear old version
	if (is_dir($tmpFolder))
	{
		system('rm -R ' . $tmpFolder);
	}
	if (file_exists($dest))
	{
		unlink($dest);
	}
	// make full copy
	mkdir($tmpFolder);
	$it = new \RecursiveIteratorIterator(
		new \RecursiveDirectoryIterator(
			'.',
			\RecursiveDirectoryIterator::SKIP_DOTS
		)
	);
	foreach ($it as $f)
	{
		$name = $f->getPathname();
		if (!$f->isFile()
				|| isset($ignoredFiles[$f->getBasename()])
				|| isset($ignoredExtensions[strtolower($f->getExtension())]))
		{
			continue;
		}
		$ignored = false;
		foreach ($ignoredDirs as $dir)
		{
			if (strpos($name, $dir) !== false)
			{
				$ignored = true;
				break;
			}
		}
		if ($ignored)
		{
			continue;
		}
		// TODO!!! use mkdir and copy functions
		system('cp --verbose --parents '
			. str_replace(DIRECTORY_SEPARATOR, '/', $name) . ' ' . $tmpFolder);
	}
	unset($it);

	// convert lang files to windows-1251
	echo "\nconverting...\n";
	chdir($tmpFolder);
	HandleConvWinAction();

	chdir('..');
	echo "\narchiving...\n";
	system('tar -zcvf ' . $dest . ' ' . $tmpFolder);
}

switch ($_SERVER['argv'][1])
{
	case 'utf':
		(empty($_SERVER['argv'][2]) || !file_exists($_SERVER['argv'][2]) || is_dir($_SERVER['argv'][2]))?
			HandleConvUtfAction() : HandleConvUtfFileAction($_SERVER['argv'][2]);
		break;
	case 'win':
		HandleConvWinAction();
		break;
	case 'modpack':
		HandleModPackAction();
		break;
	default:
		break;
}
