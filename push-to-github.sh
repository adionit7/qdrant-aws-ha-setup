#!/bin/bash
# Helper script to push to GitHub

echo "🚀 Qdrant AWS HA Setup - GitHub Push Helper"
echo "==========================================="
echo ""

# Check if repo exists on GitHub
echo "Checking if repository exists on GitHub..."
REPO_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/adionit7/qdrant-aws-ha-setup)

if [ "$REPO_EXISTS" = "200" ]; then
    echo "✅ Repository already exists on GitHub!"
    echo ""
    echo "Pushing code..."
    git push -u origin main
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Success! Your code is on GitHub:"
        echo "   https://github.com/adionit7/qdrant-aws-ha-setup"
    else
        echo ""
        echo "❌ Push failed. You may need to:"
        echo "   1. Create a Personal Access Token at: https://github.com/settings/tokens"
        echo "   2. Use the token as your password when prompted"
        echo ""
        echo "Or use SSH:"
        echo "   git remote set-url origin git@github.com:adionit7/qdrant-aws-ha-setup.git"
        echo "   git push -u origin main"
    fi
else
    echo "❌ Repository doesn't exist yet on GitHub."
    echo ""
    echo "Please create it first:"
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: qdrant-aws-ha-setup"
    echo "3. Description: High Availability Qdrant Cluster on AWS"
    echo "4. Make it Public"
    echo "5. DO NOT initialize with README/gitignore/license"
    echo "6. Click 'Create repository'"
    echo ""
    echo "Then run this script again, or run:"
    echo "   git push -u origin main"
    echo ""
    echo "When prompted for password, use a Personal Access Token:"
    echo "   Create one at: https://github.com/settings/tokens"
fi
