# Password-Protected Content Extension For Quarto

A Quarto extension that allows you to password-protect content in HTML documents, perfect for progressively revealing solutions during lectures or workshops. The encryption is not secure and hence suitable for educational use only, not sensitive data.

## Installation

```bash
quarto add pcerf/quarto-password-content
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

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

### Behavior

**When `include-solutions: false` (student view):**
- Content is encrypted and hidden
- A password input field is displayed
- Students must enter the correct 5-character password to reveal
- Password is automatically generated from the solution's `name` attribute

**When `include-solutions: true` (instructor view):**
- Content is visible
- A collapsible blue info box shows the solution name and password
- Click to reveal the password
- Share passwords with students during class to unlock solutions

## Features

- **Encryption**: Passwords not stored in HTML source (only hash); content encrypted with XOR cipher
- **Security**: Suitable for educational use only, not sensitive data
- **Stable passwords**: Based on solution name, not content (won't change when you edit)
- **Deterministic**: Same name always generates same password
- **Session persistence**: Once unlocked, stays unlocked during browser session
- **Clean UI**: Professional password entry interface with collapsible password boxes
- **Keyboard support**: Press Enter to submit password


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

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

**See it in action:**

- [Student view](https://htmlpreview.github.io/?https://github.com/pcerf/quarto-password-content/blob/main/example.html) - Solutions are password-protected
- [Instructor view](https://htmlpreview.github.io/?https://github.com/pcerf/quarto-password-content/blob/main/example-instructor.html) - Shows passwords for each solution

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

## Tips

- Each solution gets a unique password based on its `name` attribute
- Passwords remain stable even if you modify the solution content
- Use descriptive names like "exercise-1", "pipeline-solution", "data-cleaning"
- Keep an instructor copy rendered with `include-solutions: true` for reference
- Passwords are 5 characters (uppercase letters and numbers, excluding similar-looking characters)

## Notes

- The `content-password` div only works with HTML output formats
- Content is encrypted client-side for security
- Once unlocked, content remains visible during the browser session
- Passwords are deterministically generated from the solution name
