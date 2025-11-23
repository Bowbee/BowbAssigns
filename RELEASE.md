# Releasing BowbAssigns

## CurseForge Release Process

This addon uses GitHub Actions to automatically publish releases to CurseForge.

### Prerequisites

You need to set up the following secrets in your GitHub repository:

1. **CURSEFORGE_TOKEN**: Your CurseForge API token
   - Get this from: https://www.curseforge.com/account/api-tokens
   - Required scopes: "Upload File"

2. **CURSEFORGE_PROJECT_ID**: Your CurseForge project ID
   - Find this in your project's URL or settings

### Setting up Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add both secrets mentioned above

### Creating a Release

To create a new release:

1. Update the version in `BowbAssigns.toc` if desired (optional - the workflow will update it)
2. Commit your changes
3. Create and push a version tag:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

The GitHub Action will automatically:
- Extract the version from the tag
- Update the TOC file with the version
- Package the addon
- Upload to CurseForge

### Version Tag Format

Use semantic versioning with a `v` prefix:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release  
- `v1.0.1` - Patch release

### Monitoring Releases

Check the **Actions** tab in your GitHub repository to monitor the release progress.

