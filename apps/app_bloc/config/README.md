# Build configuration

One file per environment, passed at build time:

```sh
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

These values are compiled into the app and can be read by anyone who has the
binary. **Do not put secrets here.** Keep API secrets on your backend.

| Key | Required | Values |
| --- | --- | --- |
| `APP_ENV` | yes | `dev`, `staging`, `prod` (must match `--flavor`) |
| `API_BASE_URL` | yes | absolute `https` URL (`http` allowed in `dev` only) |
| `LOG_LEVEL` | no (default `info`) | `debug`, `info`, `warning`, `error`, `off` (`debug` rejected in prod) |
| `NETWORK_LOGS` | no (default `false`) | `true`, `false` (`true` rejected in prod) |
| `GRAPHQL_URL` | no | absolute `https` URL of a GraphQL endpoint. When set, the posts feature uses GraphQL instead of REST. |

`dev_graphql.json` is `dev` with `GRAPHQL_URL` pointing to the public
[GraphQLZero](https://graphqlzero.almansi.me) API (same data as
JSONPlaceholder), so you can try the GraphQL data source:

```sh
flutter run --flavor dev --dart-define-from-file=config/dev_graphql.json
```

`staging.json` and `prod.json` point to placeholder hosts. The prod build
refuses to start until `API_BASE_URL` is a real host. See
`docs/environment-configuration.md`.
