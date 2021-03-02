
// BUILD: dart compile exe bx.dart

// EXAMPLE: https://dart.dev/tutorials/server/cmdline
// EXAMPLE: dart create -t console-full cli

import 'dart:io';
import 'dart:convert';
import 'dart:async';

die(msg) {
	print(msg);
	exit(0);
}

require_site_root(basePath) {
	if (basePath == '') {
		die("Site root not found.\n");
	}
}

// https://api.dart.dev/be/178268/dart-io/dart-io-library.html
check_command(cmd) async {
	ProcessResult result = await Process.run('which', [cmd]);
    return result.exitCode == 0;
}

require_command(cmd) async {
	ProcessResult result = await Process.run('which', [cmd]);
    if (result.exitCode != 0) {
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

run(cmd, args) async {
	if (is_bx_debug()) {
        print(cmd + ' ' + args.join(' '));
    }
	ProcessResult result;
	try {
		result = await Process.run(cmd, args);
	}
	catch (e) {
		return -1;
	}

    return result.exitCode;
}

//TODO!!! test on ubuntu
sudo_run(cmd, args) async {
	if (!await is_ubuntu()) {
        //return run(cmd, args);
    }
    var ENV = Platform.environment;
    if ((ENV['BX_ROOT_USER'] != null) && (ENV['BX_ROOT_USER'] == '1')) {
        return run(cmd, args);
    }
	if (is_bx_debug()) {
        print('sudo ' + cmd + ' ' + args.join(' '));
    }
	ProcessResult result;
	try {
		args.unshift(cmd);
		result = await Process.run('sudo', args);
	}
	catch (e) {
		return -1;
	}

    return result.exitCode;
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
		'-L',
		"'$url'",
		'-A',
		"'" + request_useragent() + "'"
	];
	if (outfile != '') {
		args.add('-o');
		args.add("'$outfile'");
	}

	return run('curl', args);
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

	print(await request_get('https://google.com/', '_test.log'));

	print('OK.');
}
