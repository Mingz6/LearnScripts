# .NET CLI Commands

This document provides a list of commonly used .NET CLI commands for managing .NET projects.

## Commands

### Restore Dependencies
Restores the dependencies and tools of a project.
```sh
dotnet restore
```

Build Project
Builds the project and its dependencies.
```sh
dotnet build
```

Clean Project
Cleans the output of the previous build.
```sh
dotnet clean
```

Rebuild Project
Cleans and then builds the project.
```sh
dotnet build --no-incremental
```

Combined Clean and Build
Cleans and then builds the project in one command.

```sh
dotnet clean; dotnet build;
```

Useful [Link](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet)

For more information on .NET CLI commands, visit the official documentation.