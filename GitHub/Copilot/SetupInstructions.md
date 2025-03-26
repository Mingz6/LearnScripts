Prompt: created .github/copilot-instructions.md file based on #codebase
Link: https://code.visualstudio.com/docs/copilot/copilot-tips-and-tricks#_personalize-copilot-with-custom-instructions
Link: https://code.visualstudio.com/blogs/2025/03/26/custom-instructions#_customize-all-the-things

sample:
# Custom instructions for Copilot

## Project context
This project is an enterprise microservice architecture built with .NET. The solution contains multiple microservices organized by domain (Person, Application, Payment, Education, Employment, etc.) with Azure-based infrastructure.

## Solution structure
- Core projects contain shared functionality
- Each domain has its own folder with implementation and test projects
- Function Apps are used for serverless components

## Indentation
We use tabs, not spaces.

## Coding style
- Use camelCase for variable names and PascalCase for class names
- Use dependency injection for services
- Follow C# naming conventions:
  - Interfaces should be prefixed with "I"
  - Private fields should be prefixed with "_"
- Prefer modern C# features (async/await, expression-bodied members)

## Testing
- We use xUnit for unit testing
- Test projects follow the naming convention "[ProjectName].Test"
- Use mock objects for dependencies in unit tests (using the REGI.FuncApps.Test.Mock helpers)
