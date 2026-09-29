// Verifies workspace-wide rules that the analyzer cannot check:
//
// - every workspace member resolves through the workspace and has tests;
// - SDK constraints match the root;
// - dependency direction: packages never depend on apps, framework-free
//   packages stay free of Flutter, and state management/routing stay in apps;
// - no circular dependencies between workspace packages.
//
// Usage: dart run tool/check_packages.dart   (or: melos run check:packages)
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Packages that must stay pure Dart (usable from CLIs, servers, isolates).
const pureDartPackages = {'core', 'networking'};

/// Dependencies that belong to applications only: state management and
/// routing are app decisions, so shared packages stay usable by any app.
const appOnlyDependencies = {
  'flutter_riverpod',
  'riverpod',
  'flutter_bloc',
  'bloc',
  'go_router',
};

void main() {
  final root = Directory.current;
  final rootPubspec = _readYaml(File('${root.path}/pubspec.yaml'));
  final rootSdk = (rootPubspec['environment'] as YamlMap)['sdk'];
  final members = _workspaceMembers(root, rootPubspec['workspace'] as YamlList);

  final problems = <String>[];
  final graph = <String, Set<String>>{};
  final kinds = <String, String>{};

  for (final dir in members) {
    final relative = dir.path.substring(root.path.length + 1);
    final pubspec = _readYaml(File('${dir.path}/pubspec.yaml'));
    final name = pubspec['name'] as String;
    kinds[name] = relative.startsWith('apps/') ? 'app' : 'package';

    if (pubspec['resolution'] != 'workspace') {
      problems.add('$relative: missing "resolution: workspace".');
    }
    final sdk = (pubspec['environment'] as YamlMap?)?['sdk'];
    if (sdk != rootSdk) {
      problems.add('$relative: SDK constraint "$sdk" differs from "$rootSdk".');
    }

    final testDir = Directory('${dir.path}/test');
    final hasTests =
        testDir.existsSync() &&
        testDir
            .listSync(recursive: true)
            .any((f) => f.path.endsWith('_test.dart'));
    if (!hasTests) problems.add('$relative: no tests found under test/.');

    final dependencies = {
      ...?(pubspec['dependencies'] as YamlMap?)?.keys.cast<String>(),
    };
    graph[name] = dependencies;

    if (kinds[name] == 'package') {
      if (pureDartPackages.contains(name) && dependencies.contains('flutter')) {
        problems.add('$relative: must not depend on Flutter.');
      }
      for (final dep in dependencies.intersection(appOnlyDependencies)) {
        problems.add(
          '$relative: depends on "$dep"; state management and routing '
          'belong in apps.',
        );
      }
    }
  }

  // Workspace-internal edges only.
  for (final entry in graph.entries) {
    entry.value.retainAll(graph.keys);
    for (final dep in entry.value) {
      if (kinds[entry.key] == 'package' && kinds[dep] == 'app') {
        problems.add('${entry.key}: packages must not depend on app "$dep".');
      }
    }
  }
  problems.addAll(_cycles(graph).map((c) => 'Circular dependency: $c'));

  stdout.writeln('Checked ${members.length} workspace members:');
  for (final name in graph.keys.toList()..sort()) {
    final deps = graph[name]!.toList()..sort();
    stdout.writeln(
      '  $name (${kinds[name]}) -> ${deps.isEmpty ? '-' : deps.join(', ')}',
    );
  }

  if (problems.isEmpty) {
    stdout.writeln('All package checks passed.');
    return;
  }
  stderr.writeln('\n${problems.length} problem(s):');
  for (final problem in problems) {
    stderr.writeln('  - $problem');
  }
  exitCode = 1;
}

YamlMap _readYaml(File file) {
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}');
    exit(1);
  }
  return loadYaml(file.readAsStringSync()) as YamlMap;
}

/// Expands the root `workspace` list. Supports literal paths and a trailing
/// `/*` glob, which is all this repository uses.
List<Directory> _workspaceMembers(Directory root, YamlList entries) {
  final members = <Directory>[];
  for (final entry in entries.cast<String>()) {
    if (entry.endsWith('/*')) {
      final parent = Directory('${root.path}/${entry.replaceAll('/*', '')}');
      if (!parent.existsSync()) continue;
      members.addAll(
        parent.listSync().whereType<Directory>().where(
          (d) => File('${d.path}/pubspec.yaml').existsSync(),
        ),
      );
    } else {
      members.add(Directory('${root.path}/$entry'));
    }
  }
  return members..sort((a, b) => a.path.compareTo(b.path));
}

List<String> _cycles(Map<String, Set<String>> graph) {
  final cycles = <String>[];
  final state = <String, int>{}; // 1 = visiting, 2 = done
  final stack = <String>[];

  void visit(String node) {
    state[node] = 1;
    stack.add(node);
    for (final dep in graph[node]!) {
      if (state[dep] == 1) {
        cycles.add([...stack.sublist(stack.indexOf(dep)), dep].join(' -> '));
      } else if (state[dep] == null) {
        visit(dep);
      }
    }
    stack.removeLast();
    state[node] = 2;
  }

  for (final node in graph.keys) {
    if (state[node] == null) visit(node);
  }
  return cycles;
}
