
set -x
echo Decrypting id_rsa...

mkdir -p sshconfig

if [ ! -z $gh_rsa_key ]; then
    openssl enc -aes-256-cbc -K $gh_rsa_key -iv $gh_rsa_iv -in .github/id_rsa.enc -out sshconfig/id_rsa -d
elif [ ! -z $encrypted_b1899526f957_key ]; then
    openssl aes-256-cbc -K $encrypted_b1899526f957_key -iv $encrypted_b1899526f957_iv -in travis/id_rsa.enc -out sshconfig/id_rsa -d
else
    echo "Can't decrypt ssh key"

fi

eval "$(ssh-agent -s)"
chmod 600 sshconfig/id_rsa
ssh-add sshconfig/id_rsa 

SSHOPTS="ssh -o StrictHostKeyChecking=no"

VERSION=`cat PORTABLE_VERSION | perl -ne 's/\R//g and print'`
echo $VERSION

if [ ! -z $GITHUB_REF ]; then
    TRAVIS_BRANCH=${GITHUB_REF#"refs/heads/"}
    echo "Ref: $GITHUB_REF"
    echo "Branch: $TRAVIS_BRANCH"
fi

case "$TRAVIS_OS_NAME" in
    linux)
        echo Uploading linux artifacts...
        rsync -e "$SSHOPTS" deadbeef-*.tar.bz2 waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/linux/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" portable_out/build/*.tar.bz2 waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/linux/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" package_out/x86_64/debian/*.deb waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/linux/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" package_out/x86_64/arch/*.pkg.tar.xz waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/linux/$TRAVIS_BRANCH/ || exit 1
    ;;
    osx)
        echo Uploading mac artifacts...
        rsync -e "$SSHOPTS" osx/build/Release/deadbeef-$VERSION-osx-x86_64.zip waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/osx/$TRAVIS_BRANCH/ || exit 1
    ;;
    windows)
        echo Uploading windows artifacts...
        rsync -e "$SSHOPTS" bin/deadbeef-$VERSION-windows-x86_64.zip waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/windows/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" bin/deadbeef-$VERSION-windows-x86_64_DEBUG.zip waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/windows/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" bin/deadbeef-$VERSION-windows-x86_64.exe waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/windows/$TRAVIS_BRANCH/ || exit 1
        rsync -e "$SSHOPTS" bin/deadbeef-$VERSION-windows-x86_64_DEBUG.exe waker,deadbeef@frs.sourceforge.net:/home/frs/project/d/de/deadbeef/travis/windows/$TRAVIS_BRANCH/ || exit 1
        taskkill //IM ssh-agent.exe //F
    ;;
esac
