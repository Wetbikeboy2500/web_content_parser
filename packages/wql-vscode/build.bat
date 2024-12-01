@echo off
cd ../wql_language_server
dart pub get
dart compile exe bin/server.dart -o ../wql-vscode/out/server.exe