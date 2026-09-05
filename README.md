# personal-blog

Crystal and Kemal site deployed to [core-code.net](https://core-code.net).

## Local server

```sh
shards install
crystal run src/app.cr
open http://localhost:3000
```

## Production build

```sh
GIT_SHA=local crystal build --release src/app.cr -o bin/app
```

Pushes to `main` build with Crystal 1.21.0, restart the `personal-blog`
systemd unit, and verify `/deployment` through GitHub Actions.