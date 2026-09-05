# personal-blog

Crystal-built static site deployed to [core-code.net](https://core-code.net).

## Local build

```sh
crystal run src/build.cr
open public/index.html
```

Pushes to `main` build with Crystal 1.21.0 and deploy through GitHub Actions.
