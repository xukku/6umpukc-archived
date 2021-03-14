
import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
	if (args.length == 0) {
		return;
	}

	var tmp = args[0].split('\\bitrix\\modules\\');
	if (tmp.length != 2) { // check is module dir
		return;
	}

	var basePath = tmp[0];
	var dir = 'install/js';
	var src = args[0] + '/' + dir;
	if (!Directory(src).existsSync()) { // check extensions dir exists
		return;
	}

	print('Symlinks for ' + src);
	var contents = new Directory(src).listSync();
    for (var f in contents) {
      if (f is Directory) {
        var relPath = p.basename(dir) + '/' + p.basename(f.path);
        var dest = basePath + '/local/' + relPath;
        if (!Directory(dest).existsSync()) {
          Directory(dest).createSync(recursive: true);
        }

        var contentsForSymlinks = new Directory(f.path).listSync();
        for (var v in contentsForSymlinks) {
          if (v is Directory) {
            var destSymlinkDir = dest + '/' + p.basename(v.path);
            print('  ' + relPath + '/' + p.basename(v.path) + ' -> ' + destSymlinkDir);
            if (Link(destSymlinkDir).existsSync()) {
              Link(destSymlinkDir).deleteSync();
            }
            Link(destSymlinkDir).createSync(v.path);
          }
        }
      }
    }

	await Future.delayed(Duration(seconds: 5));
}
