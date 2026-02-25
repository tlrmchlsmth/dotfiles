---
name: example
description: An example skill to demonstrate the format
---

This is an example skill. Replace it with your own.

Useful fields in the YAML frontmatter:
- `name`: creates the `/name` slash command
- `description`: tells Claude when to auto-invoke this skill
- `disable-model-invocation: true`: only the user can trigger it
- `allowed-tools`: tools Claude can use without prompting (e.g. Read, Grep, Bash)
- `context: fork`: run in an isolated subagent

Dynamic context injection with !`command`:
- OS: !`uname -s`

User arguments are available as: $ARGUMENTS
