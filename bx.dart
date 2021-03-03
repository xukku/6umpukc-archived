
// BUILD: dart compile exe bx.dart

// EXAMPLE: https://dart.dev/tutorials/server/cmdline
// EXAMPLE: dart create -t console-full cli

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

var ENV;

die(msg) {
	print(msg);
	exit(0);
}

require_site_root(basePath) {
	if (basePath == '') {
		die("Site root not found.\n");
	}
}

check_command(cmd) async {
	ProcessResult result = await Process.run('which', [cmd]);
    return result.exitCode == 0;
}

require_command(cmd) async {
	if (!await check_command(cmd)) {
    	die(cmd + ' - command not found.');
    }
}

is_bx_debug() {
	var ENV = Platform.environment;
	return (ENV['BX_DEBUG'] != null) && (ENV['BX_DEBUG'] == '1');
}

//TODO!!! test on ubuntu
is_ubuntu() async {
	if (!Platform.isLinux) {
		return false;
	}
	if (!await check_command('lsb_release')) {
		return false;
	}
	ProcessResult result;
	try {
		result = await Process.run('lsb_release', ['-a']);
	}
	catch (e) {
		return false;
	}
	if (result.exitCode != 0) {
		return false;
	}
	return (result.stdout.indexOf('Ubuntu') >= 0)
		|| (result.stdout.indexOf('ubuntu') >= 0);
}

is_mingw() async {
	var ENV = Platform.environment;
	if (ENV['MSYSTEM'] != null) {
		if ((ENV['MSYSTEM'] == 'MINGW64')
				|| (ENV['MSYSTEM'] == 'MINGW32')
				|| (ENV['MSYSTEM'] == 'MSYS')) {
			return true;
		}
	}

	return false;
}

quote_args(args) {
	var result = [];
	for (final arg in args) {
		if ((arg.indexOf(' ') >= 0)
				|| (arg.indexOf('?') >= 0)
				|| (arg.indexOf('>') >= 0)
				|| (arg.indexOf('<') >= 0)
				|| (arg.indexOf('|') >= 0)) {
			result.add("'" + arg + "'");
		} else {
			result.add(arg);
		}
	}
	return result.join(' ');
}

// https://api.dart.dev/be/178268/dart-io/dart-io-library.html
run(cmd, args) async {
	if (is_bx_debug()) {
        print(cmd + ' ' + quote_args(args));
    }
	ProcessResult result;
	try {
		result = await Process.run(cmd, args, environment: ENV);
	}
	catch (e) {
		return -1;
	}

    return result.exitCode;
}

//TODO!!! test on ubuntu
sudo_run(cmd, args) async {
	if (!await is_ubuntu()) {
        return run(cmd, args);
    }
    var ENV = Platform.environment;
    if ((ENV['BX_ROOT_USER'] != null) && (ENV['BX_ROOT_USER'] == '1')) {
        return run(cmd, args);
    }
    args.unshift(cmd);

    return run('sudo', args);
}

//TODO!!! rewrite to array
php(args) {
	var result = 'php ';
	var ENV = Platform.environment;
	if ((ENV['SOLUTION_PHP_ARGS'] != null)
			&& (ENV['SOLUTION_PHP_ARGS'] != '')) {
		result += ENV['SOLUTION_PHP_ARGS'] + ' ';
	}
	result += args;

	return result;
}

request_useragent() {
	return 'Mozilla/5.0 (X11; Linux x86_64; rv:66.0) Gecko/20100101 Firefox/66.0';
}

request_get(url, [outfile = '']) async {
	await require_command('curl');

	var args = [
		'-s',
		'-L',
		url.toString(),
		'-A',
		request_useragent().toString()
	];
	if (outfile != '') {
		args.add('-o');
		args.add(outfile.toString());
	}

	return run('curl', args);
}

zip_archive_extract(src, dest) async {
    await require_command('unzip');

	return run('unzip', [
		'-o',
		src.toString(),
		'-d',
		dest.toString()
	]);
}

archive_extract(src, dest) async {
	await require_command('tar');

	return run('tar', [
		'-xvzf',
		src.toString(),
		dest.toString()
	]);
}

file_get_contents(filename) {
	final file = new File(filename);
	return file.readAsStringSync();
}

file_put_contents(filename, content) {
	final file = new File(filename);
	file.writeAsStringSync(content);

	return 1;
}

load_env(path) async {
	Map<String, String> result = {};
	if (!File(path).existsSync()) {
		return result;
	}

	final input = new File(path).openRead();
	final fields = await input
		.transform(utf8.decoder)
		.transform(new CsvToListConverter(
			fieldDelimiter: '=',
			textDelimiter: '"',
			textEndDelimiter:  '"',
			eol: "\n"
		))
		.toList();

	for (final row in fields) {
		var key = row[0].trim();
		if (key == '') {
			continue;
		}
		if (key.substring(0, 1) == '#') {
			continue;
		}
		var value = row[1].trim();
		result[key] = value;
	}

	return result;
}

detect_site_root(path) {
	if (path == '') {
		path = Directory.current.path;
	}
	if (File(path + '/.env').existsSync()) {
		return path;
	}
	if ((path != '') && (path != p.dirname(path))) {
		return detect_site_root(p.dirname(path));
	}

	return '';
}

bitrix_minimize() async {
	var removeDirs = [
		// ненужные компоненты
		'bitrix/modules/iblock/install/components/bitrix',
		'bitrix/modules/fileman/install/components/bitrix',
		// ненужные модули
		'bitrix/modules/landing', // слишком много файлов в модуле
		'bitrix/modules/highloadblock',
		'bitrix/modules/perfmon',
		'bitrix/modules/bitrixcloud',
		'bitrix/modules/translate',
		'bitrix/modules/compression',
		'bitrix/modules/seo',
		'bitrix/modules/search',
		// ненужные демо решения
		'bitrix/modules/bitrix.sitecorporate',
		'bitrix/wizards/bitrix/demo',
	];
	for (final dir in removeDirs) {
		if (Directory(dir).existsSync()) {
			await run('rm', [
				'-Rf',
				dir
			]);
		}
	}
}

bitrix_micromize() async {
	var bitrixExcludeDirs = {
		'cache': 1,
		'managed_cache': 1,
		'modules': 1,
		'php_interface': 1,
	};
	var bitrixExcludeFiles = {
		'.settings.php': 1,
	};
	var dirName = './bitrix';

	if (!Directory(dirName).existsSync()) {
		die('Could not open '  + dirName + ' for reading');
	}

	var contents = new Directory(dirName).listSync();
	for (var f in contents) {
		var name = p.basename(f.path);
		if (bitrixExcludeDirs.containsKey(name)
				|| bitrixExcludeFiles.containsKey(name)) {
			continue;
		}
		if (f is Directory) {
			await run('rm', [
				'-Rf',
				f.path
			]);
		} else if (f is File) {
			f.deleteSync();
		}
	}

	var removeFiles = {
		'.access.php',
		//'.htaccess',
		//'index.php',
		'install.config',
		'license.html',
		'license.php',
		'readme.html',
		'readme.php',
		'web.config',
		'bitrix/modules/main/classes/mysql/database_mysql.php',
	};
	for (var fname in removeFiles) {
		if (File(fname).existsSync()) {
			File(fname).deleteSync();
		}
	}
}

void main(List<String> args) async {
	// test arguments
	for (final arg in args) {
		print('[' + arg.trim() + ']');
	}

	//require_site_root('');
	//await require_command('git');
	//print(await check_command('git')? 'git exists' : 'git not found');
	//print(is_bx_debug()? 'DEBUG' : 'NORMAL');
	//print(await is_ubuntu()? 'ubuntu' : 'not ubuntu');
	//print(await is_mingw()? 'is mingw' : 'not mingw');
	//await run('perl', ['-v']);
	//await sudo_run('perl', ['-v']);
	//print(php('1 2 4'));
	//await request_get('https://google.com/', '_test.log');
	//file_put_contents('.test.log', '1'); print(file_get_contents('.test.log'));

	var site_root = detect_site_root('');
	ENV = await load_env(site_root + '/.env');

	print(site_root);
	print(ENV);

	//await bitrix_minimize();
	//await bitrix_micromize();

	print('OK.');
}
