#!/bin/bash


# if the netrc enviornment variables exist, write
# the netrc file.

if [[ ! -z "${DRONE_NETRC_MACHINE}" ]]; then
	cat <<EOF > /root/.netrc
machine ${DRONE_NETRC_MACHINE}
login ${DRONE_NETRC_USERNAME}
password ${DRONE_NETRC_PASSWORD}
EOF
fi

# if the ssh_key environment variable exists, write
# the ssh key and add the netrc machine to the
# known hosts file.
if [[ ! -z "${SSH_KEY}" ]]; then
	mkdir /root/.ssh
	echo -n "$SSH_KEY" > /root/.ssh/id_rsa
	chmod 600 /root/.ssh/id_rsa

	touch /root/.ssh/known_hosts
	chmod 600 /root/.ssh/known_hosts
	ssh-keyscan -H ${DRONE_NETRC_MACHINE} > /etc/ssh/ssh_known_hosts 2> /dev/null
fi


CACHE_DIR=/gitcache/${DRONE_REPO}
REPO_DIR=$CACHE_DIR/repo
export LOCKFILE=$CACHE_DIR/lock

mkdir -p ${REPO_DIR}

function releaseLock {
  rm $LOCKFILE
}

timeout 5m bash -c 'until (set -o noclobber;>$LOCKFILE) &>/dev/null; do sleep 1; done'

trap releaseLock EXIT



# go to the shared volume and initialize the repository if necessary and clone
pushd $REPO_DIR
if [ ! -d .git ]; then
	git init
	git remote add origin ${DRONE_REMOTE_URL}
fi

if [ ! -z "$DRONE_TAG" ]
then
      echo "Checking out tag ${DRONE_TAG}..."
      git fetch origin +refs/tags/${DRONE_TAG}:
      git checkout -qf FETCH_HEAD
else
      echo "Checking out commit ${DRONE_COMMIT} in branch ${DRONE_BRANCH}"
      git fetch origin +refs/heads/${DRONE_COMMIT_BRANCH}:
      git checkout ${DRONE_COMMIT_SHA}
fi

releaseLock
trap - EXIT

# return to our working directory
popd

# use the cached git repository (on disk) as the remote
git init --shared
git remote add origin $REPO_DIR

if [ ! -z "$DRONE_TAG" ]
then
      echo "Checking out tag ${DRONE_TAG}..."
      git fetch origin ${DRONE_TAG}
      git checkout ${DRONE_TAG}
else
      echo "Checking out commit ${DRONE_COMMIT} in branch ${DRONE_BRANCH}"
      git fetch origin ${DRONE_COMMIT_SHA}
      git checkout ${DRONE_COMMIT_SHA}
fi
