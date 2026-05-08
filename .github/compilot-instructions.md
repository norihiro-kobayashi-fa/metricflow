## Git Commit Messages

- Use Converntional Commits format for commit messages.
- The format is: `<type>(<scope>): <subject>`
- `<type>` can be one of the following:
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation changes
  - `style`: Code style changes (formatting, missing semi-colons, etc.)
  - `refactor`: Code refactoring without changing functionality
  - `test`: Adding or updating tests
  - `chore`: Other changes that don't modify src or test files (e.g., build process, dependencies)
- `<scope>` is optional and can be used to specify the area of the code affected by the commit (e.g., `dbt`, `metricflow`, `docker`).
- `<subject>` is a brief description of the change, written in imperative mood (e.g., "Add", "Fix", "Update", etc.) and should be concise (ideally less than 50 characters).
