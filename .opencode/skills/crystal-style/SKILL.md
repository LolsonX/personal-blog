---
name: crystal-style
description: Review and evolve Crystal code in this repository using its agreed idioms and Evans-style publishing model.
---

# Crystal style for core-code.net

Use this as a starting guide, not a rigid lint rule. Review files in context and explain meaningful tradeoffs before broad structural changes.

## Crystal expression

- Prefer transformations such as `map` when each element becomes one result; avoid a mutable accumulator when a direct transformation is clear.
- Use `getter` for useful read-only access to object state. Keep mutation behind meaningful domain methods rather than exposing setters.
- Use `record` for small immutable value/read shapes. Use a class when identity, lifecycle, or behavior matters.
- Keep type annotations where they clarify public contracts or help Crystal infer complex boundaries; avoid redundant noise.
- Prefer constructor injection and explicit composition at startup. Do not add a dependency-injection framework for this small app without a concrete need.

## Domain and dependency boundaries

- Follow Evans-style modeling: use domain language, protect invariants in entities/aggregates, and do not treat DDD-shaped folders as sufficient modeling.
- `Publishing::Post` is the post entity/aggregate. Its lifecycle rules belong with it, not in Kemal handlers or SQLite code.
- Application services coordinate use cases. A concrete, storage-independent `PostRepository` owns retrieval behavior and maps persistence rows to domain objects.
- Inject a storage adapter into the repository. The adapter owns backend operations and query translation, returning typed persistence rows; it must not return view models such as `PublishedPost`.
- Keep SQL, SQLite migrations, and row decoding in `Publishing::Storage`. Another backend should be replaceable at the composition root without changing domain rules or use cases.
- Keep HTTP/Kemal and ECR concerns at the web boundary. Keep presentation/read shapes separate from domain entities when their needs differ.

## Verification

- Run `crystal tool format --check`, `crystal spec`, and a build after relevant changes.
- Add focused specs for domain invariants, repository mapping, and adapter persistence behavior.
- Keep local databases, screenshots, credentials, and other generated files out of commits.
