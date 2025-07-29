# Creating a GitHub Gist for the Setup Script

## Steps to Create the Gist

1. Go to https://gist.github.com

2. Create a new gist with:
   - **Filename**: `setup-ai-dev.sh`
   - **Description**: "AI Development Setup Script"
   - **Content**: Copy the entire contents of `/scripts/setup-ai-dev.sh`

3. Click "Create public gist"

4. After creating, click "Raw" button to get the raw URL. It will look like:
   ```
   https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/setup-ai-dev.sh
   ```

## Update the README

Once you have the gist URL, update the README.md to use the new URL:

```bash
# Replace with your actual gist URL
bash -c "$(curl -fsSL https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/setup-ai-dev.sh)"
```

## Important Notes

- Keep the gist updated when you modify the setup script
- The gist can be public while your main repo stays private
- You can update the gist via web interface or git (gists are git repos)

## Alternative: Using GitHub CLI

If you have GitHub CLI installed, you can create the gist with:

```bash
gh gist create scripts/setup-ai-dev.sh --public -d "AI Development Setup Script"
```