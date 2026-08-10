# Personal Claude Code Rules

## Git

- Always use `--signoff` (`-s`) when creating git commits.

## External publication and remote writes

- Never create, publish, push, submit, post, or modify anything on a remote or external service without the user's explicit permission in the current conversation.
- This includes git pushes; creating or modifying pull requests, repositories, issues, reviews, review comments, ordinary comments, releases, or tags; dispatching or cancelling remote workflows; publishing packages or container images; and sending external messages.
- A request to implement, fix, commit, finish, or prepare something does not imply permission to publish it or otherwise mutate a remote service. Read-only remote inspection and local edits or commits are allowed.
- Treat permission as scoped to the specific remote action the user authorized. Ask before any additional remote write that was not explicitly included.

## Build / Run

- Prefer to use Justfile commands when available.

## Python

- Always use `uv` instead of bare `pip` for installing packages and managing dependencies.
