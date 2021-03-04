// BUILD: dart compile exe bx.dart

// EXAMPLE: https://dart.dev/tutorials/server/cmdline
// EXAMPLE: dart create -t console-full cli

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

var ARGV;
var ENV;
var REAL_BIN = p.dirname(Platform.script.toFilePath());

die(msg) {
  print(msg);
  exit(0);
}

confirm_continue(title) async {
	print(title + " Type 'yes' to continue: ");
	//my $line = <STDIN>;
	//chomp $line;
  var line = '';
	return line.trim() == 'yes';
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
  } catch (e) {
    return false;
  }
  if (result.exitCode != 0) {
    return false;
  }
  return (result.stdout.indexOf('Ubuntu') >= 0) || (result.stdout.indexOf('ubuntu') >= 0);
}

is_mingw() {
  var ENV = Platform.environment;
  if (ENV['MSYSTEM'] != null) {
    if ((ENV['MSYSTEM'] == 'MINGW64') || (ENV['MSYSTEM'] == 'MINGW32') || (ENV['MSYSTEM'] == 'MSYS')) {
      return true;
    }
  }

  return false;
}

quote_args(args) {
  var result = [];
  for (final arg in args) {
    if ((arg.indexOf(' ') >= 0) ||
        (arg.indexOf('?') >= 0) ||
        (arg.indexOf('>') >= 0) ||
        (arg.indexOf('<') >= 0) ||
        (arg.indexOf('|') >= 0)) {
      result.add("'" + arg + "'");
    } else {
      result.add(arg);
    }
  }
  return result.join(' ');
}

// https://api.dart.dev/be/178268/dart-io/dart-io-library.html
run(cmd, args, [output = false]) async {
  if (is_bx_debug()) {
    print(cmd + ' ' + quote_args(args));
  }
  ProcessResult result;
  try {
    result = await Process.run(cmd, args, environment: ENV);
  } catch (e) {
    return -1;
  }

  if (output) {
    print(result.stdout);
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
  if ((ENV['SOLUTION_PHP_ARGS'] != null) && (ENV['SOLUTION_PHP_ARGS'] != '')) {
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

  var args = ['-s', '-L', url.toString(), '-A', request_useragent().toString()];
  if (outfile != '') {
    args.add('-o');
    args.add(outfile.toString());
  }

  return run('curl', args);
}

zip_archive_extract(src, dest) async {
  await require_command('unzip');

  return run('unzip', ['-o', src.toString(), '-d', dest.toString()]);
}

archive_extract(src, dest) async {
  await require_command('tar');

  return run('tar', ['-xvzf', src.toString(), dest.toString()]);
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
      .transform(new CsvToListConverter(fieldDelimiter: '=', textDelimiter: '"', textEndDelimiter: '"', eol: "\n"))
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
      await run('rm', ['-Rf', dir]);
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
    die('Could not open ' + dirName + ' for reading');
  }

  var contents = new Directory(dirName).listSync();
  for (var f in contents) {
    var name = p.basename(f.path);
    if (bitrixExcludeDirs.containsKey(name) || bitrixExcludeFiles.containsKey(name)) {
      continue;
    }
    if (f is Directory) {
      await run('rm', ['-Rf', f.path]);
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

action_help([basePath = '']) async {
  await run('cat', [REAL_BIN + '/README.md'], true);
}

action_fetch([basePath = '']) async {
  var urlEditions = {
    'micro': 'https://www.1c-bitrix.ru/download/start_encode_php5.tar.gz',
    'core': 'https://www.1c-bitrix.ru/download/start_encode_php5.tar.gz',
    'start': 'https://www.1c-bitrix.ru/download/start_encode_php5.tar.gz',
    'business': 'https://www.1c-bitrix.ru/download/business_encode_php5.tar.gz',
    'crm': 'https://www.1c-bitrix.ru/download/portal/bitrix24_encode_php5.tar.gz',
    'setup': 'https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php',
    'restore': 'https://www.1c-bitrix.ru/download/scripts/restore.php',
    'test': 'https://dev.1c-bitrix.ru/download/scripts/bitrix_server_test.php',
  };
  var outputFile = '.bitrix.tar.gz';
  var extractOptions = './';

  var edition = (ARGV.length > 1) ? ARGV[1] : 'start';
  if (!urlEditions.containsKey(edition)) {
    edition = 'start';
  }

  if (File(outputFile).existsSync()) {
    File(outputFile).deleteSync();
  }

  if (edition == 'setup') {
    outputFile = 'bitrixsetup.php';
  } else if (edition == 'restore') {
    outputFile = 'restore.php';
  } else if (edition == 'test') {
    outputFile = 'bitrix_server_test.php';
  } else if (edition == 'micro') {
    extractOptions = './bitrix/modules';
  }
  var srcUrl = urlEditions[edition];
  print("Loading $srcUrl...");
  await request_get(srcUrl, outputFile);

  if (!File(outputFile).existsSync()) {
    die('Error on loading bitrix edition ' + srcUrl);
  }

  if ((edition == 'setup') || (edition == 'restore')) {
    exit;
  }

  print('Extracting files...');
  await archive_extract(outputFile, extractOptions);
  File(outputFile).deleteSync();

  if (edition == 'core') {
    print('Minimize for core...');
    await bitrix_minimize();
  } else if (edition == 'micro') {
    print('Micromize...');
    await bitrix_minimize();
    await bitrix_micromize();
  }
}

ftp_conn_str() {
  var ENV = Platform.environment;
  return (ENV['DEPLOY_METHOD'] ?? '') +
      '://' +
      (ENV['DEPLOY_USER'] ?? '') +
      ':' +
      (ENV['DEPLOY_PASSWORD'] ?? '') +
      '@' +
      (ENV['DEPLOY_SERVER'] ?? '') +
      (ENV['DEPLOY_PORT'] ?? '') +
      (ENV['DEPLOY_PATH'] ?? '');
}

ssh_exec_remote([cmd = '']) {
  var ENV = Platform.environment;
  var args = [
    'sshpass',
    '-p',
    (ENV['DEPLOY_PASSWORD'] ?? ''),
    'ssh',
    (ENV['DEPLOY_USER'] ?? '') + '@' + (ENV['DEPLOY_SERVER'] ?? '') + (ENV['DEPLOY_PORT'] ?? ''),
    '-t'
  ];

  if ((ENV['DEPLOY_PATH'] != null) && (ENV['DEPLOY_PATH'] != '')) {
    args.add('cd');
    args.add(ENV['DEPLOY_PATH'] ?? '');
    args.add(';');
  }

  if (cmd == '') {
    args.add('bash --login');
    args.add(';');
  }

  return args;
}

action_env(basePath) async {
  require_site_root(basePath);

  print("Site root:\n\t$basePath\n");
  print('Env config:');
  for (final k in ENV.keys) {
    print("\t" + k + " -> " + ENV[k]);
  }
  print('');
  print("Ftp connection:\n\t" + ftp_conn_str());
  print('');
  print('Ssh connection command:');
  print("\t" + quote_args(ssh_exec_remote()));
  print('');
}

action_db(basePath) async {
  require_site_root(basePath);
  await require_command('xdg-open');

  var ENV = Platform.environment;
  var url = '';
  if ((ENV['SITE_URL'] != null) && (ENV['SITE_URL'] != '')) {
    url = ENV['SITE_URL'] ?? '';
  } else {
    //TODO http or https from settings
    url = 'http://' + p.basename(basePath) + '/';
  }
  url += 'adminer/?username=' +
      (ENV['DB_USER'] ?? '') +
      '&db=' +
      (ENV['DB_NAME'] ?? '') +
      '&password=' +
      (ENV['DB_PASSWORD'] ?? '');

  return run('xdg-open', [url]);
}

action_ftp(basePath) async {
  require_site_root(basePath);
  await require_command('filezilla');

  var connStr = ftp_conn_str();
  if (is_mingw()) {
    //TODO!!!
    //    $path = $_SERVER["USERPROFILE"] . "/PortableApps/FileZillaPortable/FileZillaPortable.exe";
    //    pclose(popen("start /B " . $path . ' "' . $connStr . '" --local="' . $basePath . '"', "r"));
  } else if (is_ubuntu()) {
    await require_command('screen');
    return run('screen', ['-d', '-m', 'filezilla', connStr, '--local="' + basePath + '"']);
  }
  //else {
  //	# arch - run without `screen` command
  //	run '(filezilla "' . $conn_str . '" --local="' . $basePath . '"  &> /dev/null &)';
  //}
}

action_ssh(basePath) async {
  require_site_root(basePath);
  await require_command('ssh');
  await require_command('sshpass');

  var args = ssh_exec_remote();
  var cmd = args.shift();

  return run(cmd, args);
}

void main(List<String> args) async {
  ARGV = args;

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

  var actions = {
    'help': action_help,
    'fetch': action_fetch,
    'env': action_env,
    'ftp': action_ftp,
    'ssh': action_ssh,
    'db': action_db,
  };

  var action = '';
  if (ARGV.length == 0) {
    action = 'help';
  } else {
    action = ARGV[0];
  }
  if (!actions.containsKey(action)) {
    action = 'help';
  }

  await actions['env'](site_root);

  print('OK.');
}
