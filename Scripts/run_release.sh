#!/usr/bin/env bash
set -e

# Because `hub` is used, this script expects the following environment variables:
# GITHUB_TOKEN - github api token with repo permissions (display value in build log setting: OFF)
# GITHUB_USER - github username that GITHUB_TOKEN is associated with (display value in build log setting: ON)

# COCOAPODS_TRUNK_TOKEN - should be defined in job settings so that we can `pod trunk push`

MYREPO=${HOME}/workdir/${REPO_SLUG}

ARCH="amd64"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS" in
mingw* | msys* ) OS=windows ;;
esac

[[ $OS == 'windows' ]] && windows=1

download() {
  case "$OS" in
  windows )
    WINDOWS_URL=$(curl -u $GITHUB_USER:$GITHUB_TOKEN https://api.github.com/repos/$1/$2/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("windows-amd64")) | .browser_download_url')
    echo "$WINDOWS_URL"
    curl -fsSLO "$WINDOWS_URL"
    unzip "$(basename "$WINDOWS_URL")" bin/hub.exe
    rm -f "$(basename "$WINDOWS_URL")"
    ;;
  darwin )
    DARWIN_URL=$(curl -u $GITHUB_USER:$GITHUB_TOKEN https://api.github.com/repos/$1/$2/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("darwin-amd64")) | .browser_download_url')
    curl -fsSL "$DARWIN_URL" -o - | tar xz --strip-components=1 '*/bin/hub'
    ;;
  * )
    LINUX_URL=$(curl -u $GITHUB_USER:$GITHUB_TOKEN https://api.github.com/repos/$1/$2/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("linux-amd64")) | .browser_download_url')
    curl -fsSL "$LINUX_URL" | tar xz --strip-components=1 --wildcards '*/bin/hub'
    ;;
  esac
}

function install_binary {
	mkdir -p ~/bin

  # https://code-maven.com/create-temporary-directory-on-linux-using-bash
  tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
  
  cd $tmp_dir

  download $1 $2

	if [ ! -f "$tmp_dir/bin/hub${windows:+.exe}" ]; then
		echo "Failed to obtain $tmp_dir/bin/hub${windows:+.exe}"
		exit 1	
	fi
  mkdir -p ~/bin/
  mv $tmp_dir/bin/hub${windows:+.exe} ~/bin/

	chmod +x ~/bin/hub${windows:+.exe}
  pwd
  # verify
  ~/bin/hub${windows:+.exe} version

  # cleanup
  rm -rf $tmp_dir
  echo "hub installed"
  # cp ~/bin/hub .
}

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
  HOME=$(pwd)
  pwd
  install_binary mislav hub
  hub version
  hub release create v${VERSION} -m "Release ${VERSION}" -m "${DESCRIPTION}" -t "${BRANCH}"
}

function release_cocoapods {
  
  # - cocoapods requires ENV['HOME'] with absolute path
  HOME=$(pwd)
  gem install cocoapods -v $COCOAPODS_VERSION

  # ---- Optimizely's pods ----
  pods=(OptimizelySwiftSDK);
  number_pods=${#pods[@]};

  # ---- push podspecs to cocoapods ----
  # The podspecs need to be pushed in the correct order because of dependencies!
  printf "\n\nPushing podspecs to COCOAPODS.ORG .\n";
  for (( i = 0; i < ${number_pods}; i++ ));
  do
    podname=${pods[i]};
    printf "Pushing the ${podname} pod to COCOAPODS.ORG .\n"
    pod _${COCOAPODS_VERSION}_ trunk push --allow-warnings ${podname}.podspec
    pod _${COCOAPODS_VERSION}_ update
  done

}

function main {
  prep_workspace
  release_github
  release_cocoapods
}

main
