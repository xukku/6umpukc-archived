<?php

if (empty($_SERVER['argv'][1]))
{
	exit(1);
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
		if ($ext != 'php' && $ext != 'xml')
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
		if ($ext != 'php' && $ext != 'xml')
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

switch ($_SERVER['argv'][1])
{
	case 'utf':
		HandleConvUtfAction();
		break;
	case 'win':
		HandleConvWinAction();
		break;
	default:
		break;
}
