import * as path from 'path';
import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    State,
    TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;
let statusBarItem: vscode.StatusBarItem;

export async function activate(context: vscode.ExtensionContext) {
    // Create status bar item
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right);
    context.subscriptions.push(statusBarItem);

    try {
        // Get configuration
        const config = vscode.workspace.getConfiguration('wql');
        const debugMode = config.get<boolean>('debug') || false;

        // Server options with better path handling
        const serverOptions: ServerOptions = {
            run: {
                command: path.join(context.extensionPath, 'out', 'server.exe'),
                args: [],
                transport: TransportKind.stdio,
                options: {
                    env: { ...process.env, WQL_MODE: 'production' }
                }
            },
            debug: {
                command: path.join(context.extensionPath, 'out', 'server.exe'),
                args: [],
                transport: TransportKind.stdio,
                options: {
                    env: { ...process.env, WQL_MODE: 'debug' }
                }
            }
        };

        // Enhanced client options
        const clientOptions: LanguageClientOptions = {
            documentSelector: [
                { scheme: 'file', language: 'wql' }
            ],
            synchronize: {
                fileEvents: vscode.workspace.createFileSystemWatcher('**/*.wql'),
                configurationSection: 'wql'
            },
            outputChannel: vscode.window.createOutputChannel('WQL Language Server'),
            diagnosticCollectionName: 'wql'
        };

        // Create and start client
        client = new LanguageClient(
            'wqlLanguageServer',
            'WQL Language Server',
            serverOptions,
            clientOptions
        );

        // Add status bar handling
        client.onDidChangeState(event => {
            if (event.newState === State.Running) {
                statusBarItem.text = "WQL $(check)";
                statusBarItem.tooltip = "WQL Language Server Running";
            } else {
                statusBarItem.text = "WQL $(alert)";
                statusBarItem.tooltip = "WQL Language Server Not Running";
            }
            statusBarItem.show();
        });

        await client.start();

    } catch (error) {
        vscode.window.showErrorMessage(`Failed to start WQL language server: ${error}`);
        throw error;
    }
}

export async function deactivate(): Promise<void> {
    statusBarItem?.dispose();
    if (client) {
        try {
            await client.stop();
        } catch (error) {
            console.error('Error stopping client:', error);
        }
    }
}