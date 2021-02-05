import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const options = {
  'outputDir': 'output-dir',
  'url': 'url',
};

ArgResults argResults;

AnsiPen statusPen = AnsiPen()
  ..blue(bold: true);

AnsiPen errorPen = AnsiPen()
  ..red(bold: true);

void run(List<String> arguments) async {
  exitCode = 0;

  final parser = ArgParser()
    ..addOption(options['url'], abbr: 'i')
    ..addOption(options['outputDir'], abbr: 'd');

  argResults = parser.parse(arguments);

  if (!argResults.wasParsed(options['outputDir']) ||
      !argResults.wasParsed(options['url'])) {
    print("dldl --url='URL' --output-dir=''");
    exit(2);
  }

  for (var cmd in [
    'youtube-dl',
    'gallery-dl',
  ]) {
    if (!await which(cmd)) {
      print('${errorPen('[err]')} Command "$cmd" not found, is it installed?');
      exit(2);
    }
  }

  var outputDir = Directory(argResults[options['outputDir']]);
  await outputDir.create(recursive: true).catchError((err) {
    print("${errorPen('[err]')} Output directory ${outputDir.path} doesn't exist and it can't be created");
    exit(2);
  });

  var tmpDir = outputDir.createTempSync();
  var url = Uri.parse(argResults[options['url']]);

  print('${statusPen('[dldl]')} Attempting to download files on "$url"');
  [
    await Process.run('gallery-dl', [url.toString()],
        workingDirectory: tmpDir.path),
    await Process.run('youtube-dl', [url.toString()],
        workingDirectory: tmpDir.path)
  ];

  tmpDir.listSync(recursive: true).whereType<File>().forEach((file) {
    print('${statusPen('[dldl]')} Downloaded "${path.basename(file.path)}"');
    file.renameSync(path.join(outputDir.path, path.basename(file.path)));
  });

  tmpDir.deleteSync(recursive: true);
}

Future<bool> which(String cmd) async {
  var results = await Process.run('which', [cmd]);
  return results.stdout.toString().trim() != '';
}
