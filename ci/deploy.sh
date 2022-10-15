#!/usr/bin/env bash

set -e

IMG_PATH=$1

set -ux

MAX_OLD_IMAGES=3
ENDPOINT="https://gateway.storjshare.io"

# ARCH can be one of: x86, x86_64, arm
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" == "i686" ] || [ "$HOST_ARCH" == "i386" ]
then
    ARCH="x86"
elif [ "$HOST_ARCH" == "x86_64" ]
then
    ARCH="x86_64"
elif [[ $HOST_ARCH =~ .*(arm).* ]]
then
    ARCH="arm"
else
    echo "Unknown architecture ${HOST_ARCH}" >&2
    exit 11
fi

# TODO change branch here
if [[ "$TRAVIS_BRANCH" == "storj" ]]
then

    export AWS_DEFAULT_REGION=eu-west-1
    # Upload image
    # The put is done via a temporary filename in order to prevent outage on the
    # production file for a longer period of time.
    img_name=$(basename "${IMG_PATH}")
    cp "${IMG_PATH}" "${IMG_PATH}".temp
    aws s3 --endpoint-url="$ENDPOINT" cp "${IMG_PATH}".temp s3://junest-repo/junest/
    aws s3 --endpoint-url="$ENDPOINT" mv s3://junest-repo/junest/"$img_name".temp s3://junest-repo/junest/"$img_name"

    DATE=$(date +'%Y-%m-%d-%H-%M-%S')

    aws s3 --endpoint-url="$ENDPOINT" cp "s3://junest-repo/junest/$img_name" "s3://junest-repo/junest/${img_name}.${DATE}"

    # Cleanup old images
    aws s3 --endpoint-url="$ENDPOINT" ls s3://junest-repo/junest/junest-${ARCH}.tar.gz. | awk '{print $4}' | head -n -${MAX_OLD_IMAGES} | xargs -I {} aws s3 rm "s3://junest-repo/junest/{}"

    # Test the newly deployed image can be downloaded correctly
    junest setup
    junest -- echo "Installed JuNest (\$(uname -m))"
    yes | junest setup --delete
fi
