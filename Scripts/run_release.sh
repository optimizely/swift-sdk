#!/usr/bin/env bash
set -e

# Because `hub` is used, this script expects the following environment variables:
# GITHUB_TOKEN - github api token with repo permissions (display value in build log setting: OFF)
# GITHUB_USER - github username that GITHUB_TOKEN is associated with (display value in build log setting: ON)

MYREPO=${HOME}/workdir/${REPO_SLUG}

function prep_workspace {
  rm -rf ${MYREPO}
  mkdir -p ${MYREPO}
  git clone -b ${BRANCH} https://${GITHUB_TOKEN}@github.com/${REPO_SLUG} ${MYREPO}
  cd ${MYREPO}
}

function release_github {
  LAST_RELEASE=$(git describe --abbrev=0 --tags)

  if [[ ${LAST_RELEASE} == "v${VERSION}" ]]; then
    echo "${LAST_RELEASE} tag exists already (probably created while in the current release process). Skipping..."
    return
  fi

  CHANGELOG="CHANGELOG.md"

  # check that CHANGELOG.md has been updated
  NEW_VERSION_CHECK=$(grep '^## \d\+\.\d\+.\d\+' ${CHANGELOG} | awk 'NR==1' | tr -d '# ')
  if [[ ${NEW_VERSION_CHECK} != ${VERSION} ]]; then
    echo "ERROR: ${CHANGELOG} has not been updated yet."
    exit 1
  fi

  NEW_VERSION=$(grep '^## \d\+\.\d\+.\d\+' ${CHANGELOG} | awk 'NR==1')
  LAST_VERSION=$(grep '^## \d\+\.\d\+.\d\+' ${CHANGELOG} | awk 'NR==2')

  DESCRIPTION=$(awk "/^${NEW_VERSION}$/,/^${LAST_VERSION:-nothingmatched}$/" ${CHANGELOG} | grep -v "^${LAST_VERSION:-nothingmatched}$")

  hub release create v${VERSION} -m "Release ${VERSION}" -m "${DESCRIPTION}" -t "${BRANCH}"
}

function main {
  prep_workspace
  release_github
}

main
