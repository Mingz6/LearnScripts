Based on the #codebase , Help me to generated the following

github.copilot.chat.codeGeneration.instructions
github.copilot.chat.testGeneration.instructions
github.copilot.chat.reviewSelection.instructions
github.copilot.chat.commitMessageGeneration.instructions
Those instructions should be generated under the workspace level, not user level which is .vscode/setting.json

It should be using this article: 

Link: https://code.visualstudio.com/docs/copilot/copilot-customization





Code-generation instructions - provide context specific for generating code. For example, you can specify that private variables should always be prefixed with an underscore, or that singletons should be implemented a certain way. You can specify code-generation instructions in settings, or in a Markdown file in your workspace.

Test-generation instructions - provide context specific for generating tests. For example, you can specify that all generated tests should use a specific testing framework. You can specify test-generation instructions in settings, or in a Markdown file in your workspace.

Code review instructions - provide context specific for reviewing the current editor selection. For example, you can specify that the reviewer should look for a specific type of error in the code. You can specify review-selection instructions in settings, or in a Markdown file in your workspace.

Commit message generation instructions - provide context specific for generating commit messages. You can specify commit-message-generation instructions in settings, or in a Markdown file in your workspace.

Pull request title and description generation instructions - provide context specific for generating pull request titles and descriptions. You can specify pull request title and description generation instructions in settings, or in a Markdown file in your workspace.

