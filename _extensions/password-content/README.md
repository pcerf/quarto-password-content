# Password-Protected Content Extension

A Quarto extension that allows you to password-protect content in HTML documents.

## Installation

```bash
quarto add pcerf/quarto-password-content
```

## Usage

Add the filter to your document's YAML header:

```yaml
---
title: "My Lecture"
include-solutions: false  # Set to true to show passwords
filters:
  - password-content
---
```

Wrap content you want to protect:

```markdown
:::{.content-password name="my-solution"}
## Solution

Your solution content here...
:::
```

## Documentation

For full documentation, examples, and usage instructions, see the [main repository README](https://github.com/pcerf/quarto-password-content).
