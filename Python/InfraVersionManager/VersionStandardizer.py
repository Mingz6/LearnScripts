import os
import re
import sys
import json
import argparse

def find_and_replace(directory, pattern, replacement, dry_run=False):
    """
    Recursively search through directory and replace pattern with replacement in all files.
    
    Args:
        directory (str): Directory to start search from
        pattern (str): Regular expression pattern to search for
        replacement (str): Text to replace matches with
        dry_run (bool): If True, don't actually modify files, just print what would be changed
    """
    # Compile the regular expression
    regex = re.compile(pattern)
    
    # Count statistics
    files_searched = 0
    files_modified = 0
    replacements_made = 0
    
    print(f"Searching in {directory}")
    
    # Walk through directory tree
    for root, _, files in os.walk(directory):
        for filename in files:
            filepath = os.path.join(root, filename)
            
            # Skip binary files and directories that shouldn't be processed
            if should_skip_file(filepath):
                continue
                
            files_searched += 1
            
            try:
                # Try to open and read the file
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as file:
                    content = file.read()
                
                # Search for pattern
                matches = regex.findall(content)
                if matches:
                    new_content = regex.sub(replacement, content)
                    
                    # Count replacements
                    count = len(matches)
                    replacements_made += count
                    
                    if dry_run:
                        print(f"Would modify: {filepath} ({count} replacements)")
                        for match in set(matches):
                            if isinstance(match, tuple):  # In case regex returns tuples for capture groups
                                match = match[0]
                            print(f"  {match} -> {replacement}")
                    else:
                        # Write modified content back to file
                        with open(filepath, 'w', encoding='utf-8') as file:
                            file.write(new_content)
                        print(f"Modified: {filepath} ({count} replacements)")
                        files_modified += 1
                        
            except Exception as e:
                print(f"Error processing {filepath}: {e}")
    
    # Print summary
    print("\nSummary:")
    print(f"Files searched: {files_searched}")
    print(f"Files modified: {files_modified}")
    print(f"Total replacements: {replacements_made}")
    
    return files_modified, replacements_made

def should_skip_file(filepath):
    """Check if file should be skipped (binary, git, etc.)"""
    # List of directories to skip
    skip_dirs = ['.git', 'node_modules', 'venv', '.venv', '__pycache__', 'build', 'dist']
    for skip_dir in skip_dirs:
        if os.sep + skip_dir + os.sep in filepath:
            return True
    
    # Skip binary files and large files
    try:
        # Skip files larger than 10MB
        if os.path.getsize(filepath) > 10 * 1024 * 1024:
            return True
            
        # Try to detect binary files
        with open(filepath, 'rb') as file:
            chunk = file.read(1024)
            if b'\0' in chunk:  # If null byte is found, likely binary
                return True
    except:
        return True
        
    return False

def process_patterns_from_config(config_file, directory=None, dry_run=False):
    """Process patterns from a configuration file"""
    if directory is None:
        # Default to two levels up from current directory
        current_dir = os.path.dirname(os.path.dirname(os.getcwd()))
    else:
        current_dir = directory
    
    # Load configuration
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Error: Configuration file '{config_file}' not found!")
        print("Please create the configuration file with the proper format.")
        print("\nExample format:")
        print('''{
    "patterns": [
        {
            "description": "GitHub Checkout Action",
            "pattern": "actions/checkout@(v\\\\d+(\\\\.\\\\d+)*|main)",
            "replacement": "actions/checkout@v4.2.2"
        },
        {
            "description": "Azure Login Action",
            "pattern": "azure/login@(v\\\\d+(\\\\.\\\\d+)*|main)",
            "replacement": "azure/login@v2.3.0"
        }
    ]
}''')
        return 1, 0  # Return error code 1 and 0 replacements
    except json.JSONDecodeError:
        print(f"Error: Configuration file '{config_file}' is not valid JSON.")
        return 1, 0  # Return error code and 0 replacements

    print("GitHub Actions Version Standardization Tool")
    print("==========================================")
    print(f"Using configuration file: {config_file}")
    
    # Process each pattern in the configuration
    total_files_modified = 0
    total_replacements_made = 0
    patterns_processed = 0
    
    for pattern_config in config["patterns"]:
        description = pattern_config.get("description", "Unnamed pattern")
        pattern = pattern_config.get("pattern", "")
        replacement = pattern_config.get("replacement", "")
        
        if not pattern or not replacement:
            print(f"Skipping invalid pattern configuration: {pattern_config}")
            continue
            
        print(f"\nProcessing: {description}")
        print(f"Pattern: {pattern}")
        print(f"Replacement: {replacement}")
        
        # Perform the find and replace
        files_modified, replacements_made = find_and_replace(current_dir, pattern, replacement, dry_run)
        total_files_modified += files_modified
        total_replacements_made += replacements_made
        patterns_processed += 1
    
    print(f"\nCompleted processing {patterns_processed} patterns.")
    print(f"Total files modified: {total_files_modified}")
    print(f"Total replacements: {total_replacements_made}")
    
    return total_files_modified, total_replacements_made

def process_bicep_versions_from_config(config_file, directory=None, dry_run=False):
    """Process Bicep resource version patterns from a configuration file"""
    if directory is None:
        # Default to two levels up from current directory
        current_dir = os.path.dirname(os.path.dirname(os.getcwd()))
    else:
        current_dir = directory
    
    # Load configuration
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Error: Configuration file '{config_file}' not found!")
        print("Please create the configuration file with the proper format.")
        print("\nExample format:")
        print('''{
    "patterns": [
        {
            "description": "Managed Identity Resource",
            "pattern": "Microsoft.ManagedIdentity/userAssignedIdentities@(\\d{4}-\\d{2}-\\d{2}(?:-preview)?)",
            "replacement": "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30"
        },
        {
            "description": "Key Vault Resource",
            "pattern": "Microsoft.KeyVault/vaults@(\\d{4}-\\d{2}-\\d{2}(?:-preview)?)",
            "replacement": "Microsoft.KeyVault/vaults@2024-12-01-preview"
        }
    ]
}''')
        return 1, 0  # Return error code 1 and 0 replacements
    except json.JSONDecodeError:
        print(f"Error: Configuration file '{config_file}' is not valid JSON.")
        return 1, 0  # Return error code and 0 replacements

    print("Bicep Resource Version Standardization Tool")
    print("==========================================")
    print(f"Using configuration file: {config_file}")
    
    # Process each pattern in the configuration
    total_files_modified = 0
    total_replacements_made = 0
    patterns_processed = 0
    
    for pattern_config in config["patterns"]:
        description = pattern_config.get("description", "Unnamed pattern")
        pattern = pattern_config.get("pattern", "")
        replacement = pattern_config.get("replacement", "")
        
        if not pattern or not replacement:
            print(f"Skipping invalid pattern configuration: {pattern_config}")
            continue
            
        print(f"\nProcessing: {description}")
        print(f"Pattern: {pattern}")
        print(f"Replacement: {replacement}")
        
        # Perform the find and replace
        files_modified, replacements_made = find_and_replace(current_dir, pattern, replacement, dry_run)
        total_files_modified += files_modified
        total_replacements_made += replacements_made
        patterns_processed += 1
    
    print(f"\nCompleted processing {patterns_processed} Bicep resource version patterns.")
    print(f"Total files modified: {total_files_modified}")
    print(f"Total replacements: {total_replacements_made}")
    
    return total_files_modified, total_replacements_made

def main():
    """Main entry point for the script"""
    # Default directory is two levels up from current directory
    default_dir = os.path.dirname(os.path.dirname(os.getcwd()))
    
    parser = argparse.ArgumentParser(description='GitHub Actions and Bicep Version Standardization Tool')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be changed without modifying files')
    parser.add_argument('--config', default='GitHubActionVersion.json', help='Configuration file path for GitHub Actions (default: GitHubActionVersion.json)')
    parser.add_argument('--bicep-config', default='BicepVersion.json', help='Configuration file path for Bicep resources (default: BicepVersion.json)')
    parser.add_argument('--single', action='store_true', help='Run in single pattern mode')
    parser.add_argument('--pattern', help='Regular expression pattern to search for (used with --single)')
    parser.add_argument('--replacement', help='Text to replace matches with (used with --single)')
    parser.add_argument('--dir', default=default_dir, help=f'Directory to start search from (default: {default_dir})')
    parser.add_argument('--github-only', action='store_true', help='Process only GitHub Actions versions')
    parser.add_argument('--bicep-only', action='store_true', help='Process only Bicep resource versions')
    
    args = parser.parse_args()
    
    if args.single:
        if not args.pattern or not args.replacement:
            print("Error: --pattern and --replacement are required with --single mode")
            parser.print_help()
            return 1
            
        print("Version Standardization Tool - Single Pattern Mode")
        print("=================================================")
        print(f"Pattern: {args.pattern}")
        print(f"Replacement: {args.replacement}")
        print(f"Directory: {args.dir}")
        print(f"Dry run: {args.dry_run}")
        
        find_and_replace(args.dir, args.pattern, args.replacement, args.dry_run)
    else:
        # Default behavior: process both unless one is specifically excluded
        process_github = not args.bicep_only
        process_bicep = not args.github_only
        
        exit_code = 0
        
        if process_github:
            print("\n=== Processing GitHub Actions Versions ===\n")
            files_modified, replacements_made = process_patterns_from_config(args.config, args.dir, args.dry_run)
            # If error code 1 was returned, exit with error
            if files_modified == 1 and replacements_made == 0:
                exit_code = 1
        
        if process_bicep and exit_code == 0:
            print("\n=== Processing Bicep Resource Versions ===\n")
            files_modified, replacements_made = process_bicep_versions_from_config(args.bicep_config, args.dir, args.dry_run)
            # If error code 1 was returned, exit with error
            if files_modified == 1 and replacements_made == 0:
                exit_code = 1
        
        return exit_code
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
