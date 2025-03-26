Based on #codebase , help m,e to generate new the new **.prompt.md. Here is the Sample of Reusable **.prompt.md.

Link: https://code.visualstudio.com/blogs/2025/03/26/custom-instructions#_customize-all-the-things

or

"
Reusable prompts enable you to save a prompt for a specific task with its context and instructions in a file. You can then attach and reuse that prompt in chat. If you store the prompt in your workspace, you can also share it with your team.

To create a reusable prompt:

Create a prompt file with the Create Prompt command from the Command Palette.

This command creates a .prompt.md file in the .github/prompts folder at the root of your workspace.

Describe your prompt and relevant context in Markdown format.

For example, use this prompt to generate a new React form component.

Your goal is to generate a new React form component.

Ask for the form name and fields if not provided.

Requirements for the form:

Use form design system components: design-system/Form.md
Use react-hook-form for form state management:
Always define TypeScript types for your form data
Prefer uncontrolled components using register
Use defaultValues to prevent unnecessary rerenders
Use yup for validation:
Create reusable validation schemas in separate files
Use TypeScript types to ensure type safety
Customize UX-friendly validation rules Copy Add the prompt as context in chat.
Get started with reusable prompts.
"