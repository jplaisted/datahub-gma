#!/bin/bash

tag="v$1"
echo "Applying and pushing tag $tag"

EXISTING_TAGS=$(git tag --points-at HEAD)

if [[ "$EXISTING_TAGS" ]]; then
  echo "Tags already exist on HEAD: $EXISTING_TAGS"
  exit 1
fi

echo "Tagging commit"

git tag "$tag"

commit=$(git rev-parse HEAD)
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')
echo "$dt: **pushing tag $tag to repo $full_name"

git_refs_response=$(
curl -s -X POST $git_refs_url \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF
{
  "ref": "refs/tags/$tag",
  "sha": "$commit"
}
EOF
)

echo "===response"
echo "$git_refs_response"
echo "==="

git_ref_posted=$( echo "${git_refs_response}" | jq .ref | tr -d '"' )

echo "===ref"
echo "$git_ref_posted"
echo "==="

echo "::debug::${git_refs_response}"
if [ "${git_ref_posted}" = "refs/tags/${new}" ]; then
  exit 0
else
  echo "::error::Tag was not created properly."
  exit 1
fi