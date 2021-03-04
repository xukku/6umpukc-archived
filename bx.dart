// BUILD: dart compile exe bx.dart

// EXAMPLE: https://dart.dev/tutorials/server/cmdline
// EXAMPLE: dart create -t console-full cli

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

var REAL_BIN = p.dirname(Platform.script.toFilePath());
var ARGV;
var ENV_LOCAL;

chdir(dir) {
  Directory.current = dir;
}

get_env(name) {
  if (ENV_LOCAL.containsKey(name)) {
    return (ENV_LOCAL[name] ?? '');
  }
  var ENV = Platform.environment;

  return (ENV[name] ?? '');
}

die(msg) {
  print(msg);
  exit(0);
}

// TODO check https://pub.dev/packages/process_run/install
/*
system(cmd, args) {
  Process.start(cmd, args).then((process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    process.exitCode.then(print);
  });
}
*/

confirm_continue(title) {
  print(title + " Type 'yes' to continue: ");
  var line = stdin.readLineSync();

  return (line ?? '').trim() == 'yes';
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
  return get_env('BX_DEBUG') == '1';
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
  var msystem = get_env('MSYSTEM');
  if ((msystem == 'MINGW64') || (msystem == 'MINGW32') || (msystem == 'MSYS')) {
    return true;
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
run(cmd, args) async {
  if (is_bx_debug()) {
    print(cmd + ' ' + quote_args(args));
  }
  try {
    ProcessResult result = await Process.run(cmd, new List<String>.from(args), environment: ENV_LOCAL);
    print(result.stdout.trimRight());
    return result.exitCode;
  } catch (e) {
    print('Error on running command:');
    print(e);
    return -1;
  }
}

//TODO!!! test on ubuntu
sudo_run(cmd, args) async {
  if (!await is_ubuntu()) {
    return run(cmd, args);
  }
  if (get_env('BX_ROOT_USER') == '1') {
    return run(cmd, args);
  }
  args.unshift(cmd);

  return run('sudo', args);
}

run_php(args) async {
  var phpBin = get_env('SOLUTION_PHP_BIN');
  if (phpBin == '') {
    phpBin = 'php';
  } else {
    phpBin += "\\php";
  }
  var cmdArgs = [];
  var phpArgs = get_env('SOLUTION_PHP_ARGS');
  if (phpArgs != '') {
    for (final arg in phpArgs.split(' ')) {
      cmdArgs.add(arg.trim());
    }
  }
  for (final arg in args) {
    cmdArgs.add(arg);
  }

  return run(phpBin, cmdArgs);
}

request_useragent() {
  return 'Mozilla/5.0 (X11; Linux x86_64; rv:66.0) Gecko/20100101 Firefox/66.0';
}

request_get(url, [outfile = '']) async {
  await require_command('curl');

  var args = ['-s', '-L', url, '-A', request_useragent()];
  if (outfile != '') {
    args.add('-o');
    args.add(outfile);
  }

  return run('curl', args);
}

zip_archive_extract(src, dest) async {
  await require_command('unzip');

  return run('unzip', ['-o', src, '-d', dest]);
}

archive_extract(src, dest) async {
  await require_command('tar');

  return run('tar', ['-xvzf', src, dest]);
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
  await run('cat', [REAL_BIN + '/README.md']);
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
    exit(0);
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
  return get_env('DEPLOY_METHOD') +
      '://' +
      get_env('DEPLOY_USER') +
      ':' +
      get_env('DEPLOY_PASSWORD') +
      '@' +
      get_env('DEPLOY_SERVER') +
      get_env('DEPLOY_PORT') +
      get_env('DEPLOY_PATH');
}

ssh_exec_remote([cmd = '']) {
  var args = [
    'sshpass',
    '-p',
    get_env('DEPLOY_PASSWORD'),
    'ssh',
    get_env('DEPLOY_USER') + '@' + get_env('DEPLOY_SERVER') + get_env('DEPLOY_PORT'),
    '-t'
  ];

  var deployPath = get_env('DEPLOY_PATH');
  if (deployPath != '') {
    args.add('cd');
    args.add(deployPath);
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
  for (final k in ENV_LOCAL.keys) {
    print("\t" + k + " -> " + ENV_LOCAL[k]);
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

  var url = '';
  var siteUrl = get_env('SITE_URL');
  if (siteUrl != '') {
    url = siteUrl;
  } else {
    //TODO http or https from settings
    url = 'http://' + p.basename(basePath) + '/';
  }
  url +=
      'adminer/?username=' + get_env('DB_USER') + '&db=' + get_env('DB_NAME') + '&password=' + get_env('DB_PASSWORD');

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
  } else if (await is_ubuntu()) {
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

git_repos() {
  var solutionRepos = get_env('SOLUTION_GIT_REPOS').split("\n");
  var result = [];
  for (final line in solutionRepos) {
    if (line.trim() == '') {
      continue;
    }
    var tmp = line.split(';');
    result.add(tmp[0].trim());
  }

  return result;
}

git_repos_map() {
  var solutionRepos = get_env('SOLUTION_GIT_REPOS').split("\n");
  var result = {};
  for (final line in solutionRepos) {
    if (line.trim() == '') {
      continue;
    }
    var tmp = line.split(';');
    var url = tmp[0].trim();
    var k = p.basenameWithoutExtension(url);
    var v = (tmp.length > 1) ? tmp[1].trim() : '';
    result[k] = [v, url];
  }

  return result;
}

module_names_from_repos() {
  var result = [];
  for (final url in git_repos()) {
    result.add(p.basenameWithoutExtension(url));
  }
  return result;
}

git_clone(pathModules, moduleId, urlRepo) async {
  var pathModule = pathModules + moduleId;
  if (Directory(pathModule).existsSync()) {
    await run('rm', ['-Rf', pathModule]);
  }
  chdir(pathModules);
  await run('git', ['clone', urlRepo, moduleId]);
  if (Directory(pathModule).existsSync()) {
    chdir(pathModule);
    await run('git', ['config', 'core.fileMode', 'false']);
    await run('git', ['checkout', 'master']);
  }
}

fetch_repos(basePath) async {
  var pathModules = basePath + '/bitrix/modules/';
  if (!Directory(pathModules).existsSync()) {
    new Directory(pathModules).createSync(recursive: true);
  }
  var solutionRepos = git_repos();
  if (solutionRepos.length == 0) {
    return;
  }
  print('Repositories:');
  for (final u in solutionRepos) {
    print("\t$u");
  }
  if (!confirm_continue('Warning! Modules will be removed.')) {
    exit(0);
  }
  for (final urlRepo in solutionRepos) {
    print('Fetch repo ' + urlRepo + ' ...');
    await git_clone(pathModules, p.basenameWithoutExtension(urlRepo), urlRepo);
    print('');
  }
}

action_status(basePath) async {
  require_site_root(basePath);

  var pathModules = basePath + '/bitrix/modules/';
  var solutionRepos = git_repos();
  if (solutionRepos.length == 0) {
    return;
  }
  for (final urlRepo in solutionRepos) {
    chdir(pathModules + p.basenameWithoutExtension(urlRepo));
    await run('pwd', []);
    await run('git', ['status']);
    await run('git', ['branch']);
    print('');
  }
}

action_pull(basePath) async {
  require_site_root(basePath);

  var pathModules = basePath + '/bitrix/modules/';
  var solutionRepos = git_repos();
  if (solutionRepos.length == 0) {
    return;
  }
  for (final urlRepo in solutionRepos) {
    chdir(pathModules + p.basenameWithoutExtension(urlRepo));
    await run('pwd', []);
    await run('git', ['pull']);
    print('');
  }
}

action_reset(basePath) async {
  require_site_root(basePath);

  var pathModules = basePath + '/bitrix/modules/';
  var solutionRepos = git_repos();
  if (solutionRepos.length == 0) {
    return;
  }
  if (!confirm_continue('Warning! All file changes will be removed.')) {
    exit(0);
  }
  for (final urlRepo in solutionRepos) {
    chdir(pathModules + p.basenameWithoutExtension(urlRepo));
    await run('pwd', []);
    await run('git', ['reset', '--hard', 'HEAD']);
    print('');
  }
}

action_checkout(basePath) async {
  require_site_root(basePath);

  var branch = (ARGV.length > 1) ? ARGV[1] : 'master';
  var pathModules = basePath + '/bitrix/modules/';
  if (!Directory(pathModules).existsSync()) {
    new Directory(pathModules).createSync(recursive: true);
  }
  var solutionRepos = git_repos();
  if (solutionRepos.length == 0) {
    return;
  }
  for (final urlRepo in solutionRepos) {
    chdir(pathModules + p.basenameWithoutExtension(urlRepo));
    await run('pwd', []);
    await run('git', ['checkout', branch]);
    print('');
  }
}

action_fixdir(basePath) async {
  require_site_root(basePath);

  if (await is_ubuntu()) {
    var dirUser = get_env('SITE_DIR_USER');
    if (dirUser != '') {
      await sudo_run('chown', ['-R', dirUser, basePath]);
    }
    var dirRights = get_env('SITE_DIR_RIGHTS');
    if (dirRights != '') {
      await sudo_run('chmod', ['-R', dirRights, basePath]);
    }
  }
}

action_js_install() async {
  await require_command('node');
  await require_command('npm');

  await sudo_run('npm', ['install', '-g', 'google-closure-compiler']);

  var path = REAL_BIN + '/.dev/bin/esbuild';
  if (!Directory(path).existsSync()) {
    new Directory(path).createSync(recursive: true);
  }
  chdir(path);
  await run('npm', ['install', 'esbuild']);
}

action_solution_init(basePath) async {
  require_site_root(basePath);

  var solution = (ARGV.length > 1) ? ARGV[1] : '';
  var solutionConfigPath = REAL_BIN + '/.dev/solution.env.settings/' + solution + '/example.env';
  if (solution != '') {
    if (!File(solutionConfigPath).existsSync()) {
      die("Config for solution $solution not defined.");
    }
    var siteConfig = basePath + '/.env';
    var originalContent = file_get_contents(siteConfig);
    var content = file_get_contents(solutionConfigPath);
    if (originalContent.indexOf(content) < 0) {
      content = originalContent + "\n" + content + "\n";
      file_put_contents(siteConfig, content);
    }
    ENV_LOCAL = await load_env(siteConfig);
  }
  await fetch_repos(basePath);
}

action_solution_reset(basePath) async {
  require_site_root(basePath);

  if (!confirm_continue('Warning! Site public data will be removed.')) {
    exit(0);
  }

  action_fixdir(basePath);
  await run_php([REAL_BIN + '/.action_solution_reset.php', basePath]);
}

void main(List<String> args) async {
  ARGV = args;
  var site_root = detect_site_root('');
  ENV_LOCAL = await load_env(site_root + '/.env');

  //require_site_root('');
  //await require_command('git');
  //print(await check_command('git')? 'git exists' : 'git not found');
  //print(is_bx_debug()? 'DEBUG' : 'NORMAL');
  //print(await is_ubuntu()? 'ubuntu' : 'not ubuntu');
  //print(await is_mingw()? 'is mingw' : 'not mingw');
  //await run('perl', ['-v']);
  //await sudo_run('perl', ['-v']);
  //await request_get('https://google.com/', '_test.log');
  //file_put_contents('.test.log', '1'); print(file_get_contents('.test.log'));
  //await bitrix_minimize();
  //await bitrix_micromize();

  var actions = {
    // bitrix
    'help': action_help,
    'fetch': action_fetch,

    // site
    'env': action_env,
    'ftp': action_ftp,
    'ssh': action_ssh,
    'db': action_db,
    'fixdir': action_fixdir,

    // git
    'status': action_status,
    'pull': action_pull,
    'reset': action_reset,
    'checkout': action_checkout,

    // solution
    'solution-init': action_solution_init,
    'solution-reset': action_solution_reset,

    // js
    'js-install': action_js_install,
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
  await actions[action](site_root);

  //await run_php(['-i']);
  //print(git_repos());
  //print(git_repos_map());
  //print(module_names_from_repos());
  //await fetch_repos(site_root);

  print('OK.');
}
