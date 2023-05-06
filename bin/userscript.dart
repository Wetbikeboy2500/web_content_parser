import 'dart:io';

void main() {
  //build js
  Process.runSync('dart compile js -o wql.js --no-source-maps wql.dart', [], runInShell: true);
  //append the userscript header
  final input = File('wql.js');
  final output = File('wql.user.js');

  if (output.existsSync()) {
    output.deleteSync();
  }

  output.writeAsStringSync(
    '''
// ==UserScript==
// @name         WQL Scraper
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// @run-at       document-start
// ==/UserScript==
    ''');

  output.writeAsStringSync(input.readAsStringSync(), mode: FileMode.append);
}
