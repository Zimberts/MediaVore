---
description: "Regenerate Isar (*.g.dart) and injectable (injection.config.dart) output after changing models or DI wiring."
---

# Regenerate codegen

Run this after changing an Isar `@collection` model, a DI annotation, or any
`@module`/`@LazySingleton` binding:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never hand-edit `*.g.dart` or `lib/core/di/injection.config.dart`. See
`.ai/rules/codegen.md`.
