#!/bin/bash -e

# Because `hub` is used, this script expects the following environment variables:
# GITHUB_TOKEN - github api token with repo permissions (display value in build log setting: OFF)
# GITHUB_USER - github username that GITHUB_TOKEN is associated with (display value in build log setting: ON)

# Additionally, it needs the following environment variables:
# VERSION - defined in swift.yml

COLOR_RESET='\033[0m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
MYREPO=${HOME}/workdir/${REPO_SLUG}
AUTOBRANCH=${GITHUB_USER}/prepareRelease${VERSION}
BUILD_OUTPUT=/tmp/build.out
touch $BUILD_OUTPUT

function prep_workspace {
  rm -rf ${MYREPO}
  mkdir -p ${MYREPO}
  git clone -b ${BRANCH} https://${GITHUB_TOKEN}@github.com/${REPO_SLUG} ${MYREPO}
  cd ${MYREPO}
  git checkout -b ${AUTOBRANCH}
}

dump_output() {
  echo "last 100 lines of output:"
  tail -100 $BUILD_OUTPUT
}

function error_handler() {
  echo "ERROR: An error was encountered."
  dump_output
  exit 1
}

function do_stuff {
  while :; do sleep 10; echo -n .; done &
  trap "kill $!" EXIT
  trap 'error_handler' ERR

  # we need pod install or test_all.sh fails
 
  # we skip "test_all.sh" until we have a good reason to repeat it heere
  # 1. this test takes long and also flaky tests can interrupt release process
  # 2. this "test_all.sh" is supposed to pass before starting pre-release
  # 3. prep auto PRs will be tested in CI/CD before starting release process.

  # - cocoapods requires ENV['HOME'] with absolute path
  #
  # HOME=$(pwd)
  # gem install cocoapods -v $COCOAPODS_VERSION
  # pod _${COCOAPODS_VERSION}_ repo update
  # pod _${COCOAPODS_VERSION}_ install
  #
  # myscripts=( "update_version.sh ${VERSION}" "build_all.sh" "test_all.sh" )
  myscripts=( "update_version.sh ${VERSION}" "build_all.sh" )

  for i in "${myscripts[@]}"; do
    echo -n "${i} "
    echo "===== ${i} =====" >> $BUILD_OUTPUT
    Scripts/${i} >> $BUILD_OUTPUT 2>&1
    echo
  done

  dump_output
  kill $! && trap " " EXIT
}

function push_changes {
  git config user.email "optibot@users.noreply.github.com"
  git config user.name "${GITHUB_USER}"
  git add --all

  TITLE="ci(git-action): auto release prep for $VERSION"
  # an empty line required between title and description
  # a dummy ref (FSSDK-N/A) for required FSSDK checking 
  MESSAGE=$(cat <<END
${TITLE}

- [FSSDK-N/A]
END
)

  git commit -m ${TITLE} ||
    {
      case $? in
        1 )
          echo -e "${COLOR_CYAN}INFO: ${COLOR_RESET}Nothing to commit, so not creating a PR"
          exit 0
          ;;
        * )
          echo -e "${COLOR_CYAN}ERROR: ${COLOR_RESET}Unexpected exit code while trying to git commit"
          exit 1
          ;;
      esac
    }
  git push -f https://${GITHUB_TOKEN}@github.com/${REPO_SLUG} ${AUTOBRANCH}

  PR_URL=$(hub pull-request -b ${BRANCH} -h ${AUTOBRANCH} -m "${MESSAGE}") 
  echo -e "${COLOR_CYAN}ATTENTION:${COLOR_RESET} review and merge ${COLOR_CYAN}${PR_URL}${COLOR_RESET}"
  echo "then to release to cocoapods use Git action's Trigger build with the following payload:"
  echo -e "${COLOR_MAGENTA}env:${COLOR_RESET}"
  echo -e "${COLOR_MAGENTA}  - RELEASE=true${COLOR_RESET}"
}

function main {
  prep_workspace
  time do_stuff
  push_changes
}

main
