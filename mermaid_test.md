# Mermaid testing

This is just to check what Mermaid version github uses.

In a `mermaid` block including this shows the version

```text
info
```

Current version:

```mermaid
info
```

Elk test:

```mermaid
---
config:
  layout: elk
  look: handDrawn
  theme: forest
---
graph LR
    A[Square Rect] -- Link text --> B((Circle))
    A --> C(Round Rect)
    B --> D{Rhombus}
    C --> D
```

