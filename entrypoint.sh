#!/bin/sh -l

set -e  # if a command fails it stops the execution
set -u  # script fails if trying to access to an undefined variable

echo "Starts release $RELEASE_VERSION"

SOURCE_DIRECTORY="$1"
DESTINATION_REPOSITORY="$2"
DESTINATION_REPOSITORY_USERNAME="$3"
USER_EMAIL="$4"
USER_NAME="$5"
TARGET_BRANCH="$6"

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
# Setup git
git config --global user.email "$USER_EMAIL"
git config --global user.name "$USER_NAME"
git clone --single-branch --branch "$TARGET_BRANCH" "https://$DESTINATION_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@github.com/$DESTINATION_REPOSITORY.git" "$CLONE_DIR"
ls -la "$CLONE_DIR"

TARGET_DIR=$(mktemp -d)
# This mv has been the easier way to be able to remove files that were there
# but not anymore. Otherwise we had to remove the files from "$CLONE_DIR",
# including "." and with the exception of ".git/"
mv "$CLONE_DIR/.git" "$TARGET_DIR"

if [ ! -d "$SOURCE_DIRECTORY" ]
then
	echo "ERROR: $SOURCE_DIRECTORY does not exist"
	echo "This directory needs to exist when push-to-another-repository is executed"
	exit 1
fi

echo "Copy contents to target git repository"
cp -ra "$SOURCE_DIRECTORY"/. "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Files that will be pushed:"
ls -la

echo "git add:"
git add .

echo "git status:"
git status

echo "git commit:"
git commit --message "release $RELEASE_VERSION"
git tag -a $RELEASE_VERSION -m "release $RELEASE_VERSION"

echo "git push origin:"
# --set-upstream: sets de branch when pushing to a branch that does not exist
git push "https://$DESTINATION_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@github.com/$DESTINATION_REPOSITORY.git"  --follow-tags --set-upstream "$TARGET_BRANCH"

echo "$RELEASE_VERSION is released!"
