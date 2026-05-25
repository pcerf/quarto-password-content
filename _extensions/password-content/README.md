# Password-Protected Content Extension

A Quarto extension to show or hide content based on `include-solutions`, with optional password protection in HTML output.

## Installation

```bash
quarto add pcerf/quarto-password-content
```

## Usage

```yaml
---
include-solutions: false        # true = show solutions/passwords
include-solutions-override: …  # optional: overrides include-solutions
filters:
  - password-content
---
```

| `name` attribute | HTML (student)                      | HTML (instructor)   | Non-HTML (student) | Non-HTML (instructor) |
|------------------|-------------------------------------|---------------------|--------------------|-----------------------|
| any name         | password prompt + encrypted content | content + password box | absent          | content               |
| `nopass`         | absent                              | content             | absent             | content               |

```markdown
:::{.content-password name="exercise-1"}
Solution content here…
:::

:::{.content-password name="nopass"}
Content shown only in instructor view, absent elsewhere.
:::
```

Full documentation: [github.com/pcerf/quarto-password-content](https://github.com/pcerf/quarto-password-content)
