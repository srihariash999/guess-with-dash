#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Deployment to GitHub Pages..."

# 1. Build the web app
# We use /guess-with-dash/ as the base href because that's the repository name
echo "📦 Building Flutter Web App..."
flutter build web --release --base-href "/guess-with-dash/"

# 2. Check if build was successful
if [ ! -d "build/web" ]; then
  echo "❌ Build failed! Directory build/web not found."
  exit 1
fi

# 3. Deploy
echo "📤 Deploying to gh-pages branch..."
cd build/web

# Initialize a temporary git repo for the build artifacts
git init
git add .
git commit -m "Deploy to GitHub Pages $(date)"

# Force push to the gh-pages branch of the remote repo
# We assume the remote is named 'origin' and the URL is correct in the parent repo
# We need to set the remote manually since this is a fresh init
git remote add origin git@github.com:srihariash999/guess-with-dash.git
git push -f origin HEAD:gh-pages

echo "✅ Deployed successfully!"
echo "🌎 Your app should be live at: https://srihariash999.github.io/guess-with-dash/"
