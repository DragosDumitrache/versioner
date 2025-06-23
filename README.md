# Versioner

This is a language agnostic git versioning tool using tags.

## Why this repo

There are plenty of tools available that can generate a version based on Git tags.
However, they are typically:

- driven by commit messages, not configuration
- dependent on programming languages

I didn't want to have to introduce a programming language into my pipeline, especially when it was a language that had
absolutely nothing to do with my pipeline, e.g. using an action implemented in JS in a Python project.
I also didn't feel like commit messages were the way to go, typos happen, and then someone needs to go and update it
manually.

The aim has been to have a very simple approach at versioning without introducing new dependencies, and for it to be
configuration driven.

## How to use it

You can either:
- download this script into your pipeline
- use the provided [versioner-action](https://github.com/DragosDumitrache/versioner-action) 


# Versioner Script

A bash script that calculates semantic versions from git tags and branches, with support for feature branch pre-releases.

## How to Use

### Prerequisites

- Git repository with commit history
- `jq` command-line JSON processor
- Bash shell

### Basic Usage

1. **Download the script**:
   ```bash
   curl -sL https://raw.githubusercontent.com/DragosDumitrache/versioner/main/version.sh -o version.sh
   chmod +x version.sh
   ```

2. **Create version.json** in your repository root:
   ```json
   {
     "default_branch": "main",
     "major": "1",
     "minor": "0",
     "tag_prefix": "v"
   }
   ```

3. **Run the script**:
   ```bash
   ./version.sh
   ```

### Configuration Options

The `version.json` file supports the following options:

| Field | Description | Default | Example |
|-------|-------------|---------|---------|
| `default_branch` | Main branch name | `"master"` | `"main"`, `"master"` |
| `major` | Minimum major version | `"0"` | `"1"`, `"2"` |
| `minor` | Minimum minor version | `"0"` | `"0"`, `"5"` |
| `tag_prefix` | Prefix for tags and output | `""` | `"v"`, `"release-"` |

### Version Behavior

#### Main Branch
On your default branch (e.g., `main`), the script produces clean semantic versions:

```bash
# No previous tags
./version.sh
# Output: v1.0.0

# After tag v1.0.0, with 3 more commits
./version.sh  
# Output: v1.0.3

# With version constraints (major: "2", minor: "1")
./version.sh
# Output: v2.1.0 (enforces minimums)
```

#### Feature Branches
On feature branches, the script produces pre-release versions:

```bash
# On branch "feature/user-auth" 
./version.sh
# Output: v1.0.3-dev.feature-user-auth.abc1234

# On branch "bugfix/login-issue"
./version.sh  
# Output: v1.0.3-dev.bugfix-login-issue.def5678
```

#### Dirty Working Tree
When you have uncommitted changes:

```bash
./version.sh
# Main branch: v1.0.3-dirty
# Feature branch: v1.0.3-dev.feature-auth.abc1234.dirty
```

### Examples

#### Example 1: Basic Setup
```bash
# Initialize repository
git init
git config user.name "Your Name"
git config user.email "your@email.com"

# Create version configuration
cat <<EOF > version.json
{
  "default_branch": "main",
  "major": "1", 
  "minor": "0",
  "tag_prefix": "v",
  "include_v_prefix": true
}
EOF

# Download and run script
curl -sL https://raw.githubusercontent.com/DragosDumitrache/versioner/main/version.sh | bash
# Output: v1.0.0
```

#### Example 2: With Existing Tags
```bash
# After creating some tags
git tag v1.2.0
git commit -m "Add feature"
git commit -m "Fix bug"

./version.sh
# Output: v1.2.2 (v1.2.0 + 2 commits)
```

#### Example 3: Feature Branch
```bash
git checkout -b feature/api-improvement
git commit -m "Improve API"

./version.sh
# Output: v1.2.3-dev.feature-api-improvement.a1b2c3d
```

#### Example 4: No Prefix Configuration
```json
{
  "default_branch": "main",
  "major": "0",
  "minor": "1", 
  "tag_prefix": ""
}
```

```bash
./version.sh
# Output: 0.1.0 (no prefix)
```

### Integration Examples

#### CI/CD Pipeline
```bash
#!/bin/bash
VERSION=$(./version.sh)
echo "Building version: $VERSION"

# Use in Docker build
docker build -t myapp:$VERSION .

# Use in package.json
npm version $VERSION --no-git-tag-version
```

#### Makefile Integration
```makefile
VERSION := $(shell ./version.sh)

.PHONY: version
version:
	@echo $(VERSION)

.PHONY: build
build:
	docker build -t myapp:$(VERSION) .

.PHONY: tag
tag:
	git tag $(VERSION)
	git push origin $(VERSION)
```

#### Shell Script Usage
```bash
#!/bin/bash
set -e

# Get version
VERSION=$(./version.sh)
CLEAN_VERSION=${VERSION#v}  # Remove v prefix

# Check if pre-release
if [[ "$VERSION" =~ -dev\. ]]; then
    echo "Pre-release version: $VERSION"
    echo "Deploying to staging..."
else
    echo "Release version: $VERSION" 
    echo "Deploying to production..."
fi
```

### Error Handling

#### Not a Git Repository
```bash
./version.sh
# Output: 1.0.0-SNAPSHOT
```

#### Missing jq
```bash
# Install jq first
# Ubuntu/Debian:
sudo apt-get install jq

# macOS:
brew install jq

# CentOS/RHEL:
sudo yum install jq
```

#### Invalid version.json
If `version.json` is malformed, the script will use defaults and may produce unexpected results. Validate your JSON:

```bash
jq . version.json
# Should output the parsed JSON without errors
```

### Advanced Usage

#### Custom Branch Naming
The script automatically normalizes branch names:
- `feature/user-auth` → `feature-user-auth`
- `bugfix/fix_login` → `bugfix-fix-login`
- `release/v2.0` → `release-v2.0`

#### Tag Prefix Examples
```json
// With v prefix
{
  "tag_prefix": "v"
}
// Result: v1.2.3

// No prefix
{
  "tag_prefix": ""
}
// Result: 1.2.3

// Custom prefix
{
  "tag_prefix": "release-"
}
// Result: release-1.2.3
```

#### Version Constraints
Use version constraints to enforce minimum versions:

```json
{
  "major": "2",
  "minor": "1"
}
```

Even if your latest tag is `v1.5.0`, the script will output `v2.1.0` to meet the minimum requirements.

### Troubleshooting

#### Version Not Incrementing
- Ensure you're on the correct branch
- Check that commits exist since the last tag
- Verify git history with `git log --oneline`

#### Wrong Version Format
- Check `version.json` syntax with `jq . version.json`
- Ensure all values are strings: `"1"` not `1`
- Verify tag prefix matches existing tags

#### Script Returns "SNAPSHOT"
- You're not in a git repository
- Run `git init` and make at least one commit
- Ensure `.git` directory exists

### Testing

Run the included tests:
```bash
# Install bats
npm install -g bats

# Run tests
bats test.bats
```

## License

MIT
