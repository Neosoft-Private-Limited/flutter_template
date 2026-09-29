# Contributing

Thanks for helping improve the template. Contributions come as issues and
pull requests on GitHub.

## Pull requests

1. Fork the repository and branch from `main`.
2. Set up the workspace as described in the [README](README.md#getting-started).
3. Make one change per pull request. Unrelated changes (even small ones) go in
   separate pull requests so each can be reviewed and merged on its own.
4. Add or update tests for behaviour you change ([docs/testing.md](docs/testing.md)).
5. Update documentation when commands, structure or behaviour change.
6. Run the full quality gate locally:

   ```sh
   melos run validate
   ```

   CI runs the same checks plus Android, iOS and web builds. Pull requests
   that fail CI are not merged.
7. Fill in the pull request template.

Do not weaken lint rules, skip packages or delete tests to get a green build.
If a rule is wrong for a specific line, use a targeted
`// ignore: rule_name` with a comment above it explaining why. Some rules
(unawaited futures, dynamic calls, `print`, `BuildContext` across async gaps,
...) cannot be ignored at all. Public members of shared packages need `///`
docs. Details: [docs/development.md](docs/development.md#lint-rules).

## Commit messages

Use short, imperative subjects ("Add retry to posts refresh"). Explain the
reason in the body when it is not obvious from the diff.

## Keeping your fork up to date

```sh
git remote add upstream https://github.com/Neosoft-Private-Limited/flutter_template.git
git fetch upstream
git rebase upstream/main
```

## Reporting bugs

Open an issue with the **Bug report** template. Good reports include the
Flutter version (`flutter --version`), the platform, steps to reproduce, and
what you expected versus what happened.

Security issues: follow [SECURITY.md](SECURITY.md), not public issues.

## Code style

- `dart format` and the shared analyzer rules (very_good_analysis plus the
  stricter additions in `analysis_options.yaml`) are enforced.
- Conventions (naming, imports, package boundaries) are in
  [docs/development.md](docs/development.md#naming-and-file-organization) and
  [docs/architecture.md](docs/architecture.md#conventions).

## License

By contributing, you agree that your contributions are licensed under the
repository's [Apache License 2.0](LICENSE).
