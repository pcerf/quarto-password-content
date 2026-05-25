# Password-Protected Content Extension For Quarto

A Quarto extension that allows you to password-protect content in HTML documents, perfect for progressively revealing solutions during lectures or workshops. The encryption is not secure and hence suitable for educational use only, not sensitive data.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

**See it in action:**

- [Student view](https://pcerf.github.io/quarto-password-content/example.html) - Solutions are password-protected
- [Instructor view](https://pcerf.github.io/quarto-password-content/example-instructor.html) - Shows passwords for each solution

## Installation

```bash
quarto add pcerf/quarto-password-content
```

This will install the extension under the `_extensions` subdirectory.

## Usage

Add the filter to your document's YAML header:

```yaml
---
title: "My Lecture"
include-solutions: false  # Set to true to show solutions/passwords
filters:
  - password-content
---
```

### Protecting Content

Wrap content you want to protect in a div with the `content-password` class and a unique `name` attribute:

````markdown
## Exercise 1: Build a Pipeline

Try to implement this yourself first...

:::{.content-password name="pipeline-exercise"}
## Solution

```{python}
from sklearn.pipeline import Pipeline
# Your solution code here
```

This solution demonstrates...
:::
````

**Important:** The `name` attribute:
- Determines the password (same name = same password)
- Keeps password stable even if you modify the solution content
- Should be unique and descriptive (e.g., "exercise-1", "sklearn-pipeline")
- If omitted, defaults to "solution-1", "solution-2", etc.

### Unprotected Toggle: `name="nopass"`

Use `name="nopass"` for content that should be shown or hidden based solely on `include-solutions`, with **no password mechanism at all**:

```markdown
:::{.content-password name="nopass"}
This content is shown to instructors and completely absent from the student document.
:::
```

- When `include-solutions: false` — the content is **not present in the output at all** (not encrypted, not hidden with CSS, simply not rendered).
- When `include-solutions: true` — the content is rendered as-is with no password box.

### Behavior by Format

The password UI (input field, encryption, password info box) is only generated for HTML-compatible output formats (html, revealjs, epub, …).

**HTML output — `include-solutions: false` (student view):**
- Content is encrypted and hidden behind a password input field
- The encrypted data and password hash are embedded in the page; the plaintext is not

**HTML output — `include-solutions: true` (instructor view):**
- Content is visible
- A collapsible blue info box shows the password for each solution
- Share passwords with students during class to unlock solutions progressively

**Non-HTML output (PDF, docx, …) — `include-solutions: false`:**
- The block is completely absent from the output (no encrypted data, no placeholder)

**Non-HTML output (PDF, docx, …) — `include-solutions: true`:**
- Content is rendered natively with no password UI or password shown

### Overriding `include-solutions` at Render Time

Use `include-solutions-override` to override the document's `include-solutions` value without editing the file. This takes precedence over `include-solutions` when present:

```bash
quarto render lecture.qmd -M include-solutions-override:true
```

Or set it in the YAML front matter:

```yaml
include-solutions: false
include-solutions-override: true  # wins
```

## Features

- **Encryption**: Passwords not stored in HTML source (only hash); content encrypted with XOR cipher
- **Security**: Suitable for educational use only, not sensitive data
- **Stable passwords**: Based on solution name, not content (won't change when you edit)
- **Deterministic**: Same name always generates same password
- **Session persistence**: Once unlocked, stays unlocked during browser session
- **Clean UI**: Professional password entry interface with collapsible password boxes
- **Keyboard support**: Press Enter to submit password
- **Format-aware**: Password/encryption data only emitted for HTML-compatible formats
- **Unprotected toggle**: `name="nopass"` for content that needs no password, just show/hide

## Example Workflow

1. **Before class**: Render with `include-solutions: false`
   ```bash
   quarto render lecture.qmd
   ```

2. **During class**: Open instructor version with `include-solutions: true`
   ```bash
   quarto render lecture.qmd -M include-solutions:true
   ```

3. **Share passwords**: As you progress, share passwords verbally or via chat

4. **Students unlock**: Students enter passwords to reveal solutions at their own pace

## Use Cases

The password-protected content extension is particularly useful for:

- **Educational settings**: Progressively reveal solutions during lectures
- **Workshops**: Allow participants to work at their own pace
- **Self-paced learning**: Provide hints and solutions that learners can unlock
- **Interactive tutorials**: Hide answers until students attempt exercises

## Technical Details

- **Password generation**: Hash of solution name (not content)
- **Password verification**: One-way hash stored in HTML (password not recoverable)
- **Encryption**: XOR cipher with password as key
- **Storage**: Encrypted content embedded in HTML as hex string
- **Decryption**: Client-side JavaScript when correct password entered
- **Password format**: 5 characters (uppercase letters and numbers, excluding similar-looking characters)
- **Non-HTML formats**: Encrypted data and passwords are never written; content is either shown natively or omitted entirely

## Changelog

### v1.1.0

- **`name="nopass"`** — new option for content that should be shown or hidden based solely on `include-solutions`, with no password mechanism. When hidden the content is entirely absent from the output (not encrypted, not CSS-hidden).
- **`include-solutions-override`** — new metadata key that overrides `include-solutions` when present, useful for command-line rendering without editing the document.
- **Format-aware output** — encrypted data, password hashes, and the password UI are only emitted for HTML-compatible formats (html, revealjs, epub, …). In non-HTML formats (PDF, docx, …), protected content is either rendered natively (instructor view) or completely omitted (student view).

### v1.0.0

- Initial release
- Password-protected content via `.content-password` divs
- Password derived from `name` attribute (stable across content edits)
- XOR encryption with client-side decryption
- Session persistence (stays unlocked during browser session)
- Collapsible password info box in instructor view
