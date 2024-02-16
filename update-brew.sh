gcurl() {
  curl -sS \
    -H "Authorization: token $PERSONAL_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$@"
}

LATEST_VERSION=$(gcurl https://api.github.com/repos/pulsar-edit/pulsar/releases/latest | jq -r '.tag_name | gsub("^v";"")')
echo "Latest Pulsar version: $LATEST_VERSION" >> $GITHUB_STEP_SUMMARY
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_OUTPUT

BREW_VERSION_RAW=$(gcurl https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/pulsar.rb | grep -m 1 'version')
BREW_VERSION_TS="${BREW_VERSION_RAW:11}"
BREW_VERSION="${BREW_VERSION_TS%?}"
echo "Latest Brew version: $BREW_VERSION" >> $GITHUB_STEP_SUMMARY
echo "BREW_VERSION=$BREW_VERSION" >> $GITHUB_OUTPUT

echo "" >> $GITHUB_STEP_SUMMARY
if [ "$LATEST_VERSION" = "$BREW_VERSION" ]; then
  echo "Brew is up to date" >> $GITHUB_STEP_SUMMARY
  echo "UPDATE=false" >> $GITHUB_OUTPUT
  exit 0
fi

POSSIBLE_PRS_FILE=$(mktemp)

echo "Brew is out of date, checking for update PRs" >> $GITHUB_STEP_SUMMARY
gcurl --get \
  --data-urlencode "q=repo:Homebrew/homebrew-cask type:pr in:title pulsar $LATEST_VERSION" \
  --output $POSSIBLE_PRS_FILE \
  "https://api.github.com/search/issues"

POSSIBLE_PR_URL=$(jq '.items[].pull_request.html_url' $POSSIBLE_PRS_FILE)
HAS_POSSIBLE_PRS=$(jq '.items | length > 0' $POSSIBLE_PRS_FILE)

echo "PR_URL=$POSSIBLE_PR_URL" >> $GITHUB_OUTPUT
rm $POSSIBLE_PRS_FILE
  
if [ "$HAS_POSSIBLE_PRS" = "true" ]; then
  echo "There is a PR found for this update: $POSSIBLE_PR_URL" >> $GITHUB_STEP_SUMMARY
  echo "UPDATE=false" >> $GITHUB_OUTPUT
  exit 0
fi

echo "No PR found for this update" >> $GITHUB_STEP_SUMMARY
echo "UPDATE=true" >> $GITHUB_OUTPUT
