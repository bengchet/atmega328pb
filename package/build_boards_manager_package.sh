#!/bin/bash
#

# Figure out how will the package be called
ver=`git describe --tags --always`
package_name=atmega328pb-$ver
echo "Version: $ver"
echo "Package name: $package_name"

PKG_URL=https://github.com/CytronTechnologies/atmega328pb-board-package/releases/download/$ver/$package_name.zip
DOC_URL=http://forum.cytron.com.my/

pushd ..

# Create directory for the package
outdir=package/versions/$ver/$package_name
srcdir=$PWD
rm -rf package/versions/$ver
mkdir -p $outdir

# Some files should be excluded from the package
cat << EOF > exclude.txt
package_cytron_m328pb_index_stable.json
.git
.gitignore
.travis.yml
mkdocs.yml
exclude.txt
package
docs
EOF
rsync -a --exclude-from 'exclude.txt' $srcdir/ $outdir/
rm exclude.txt

pushd package/versions/$ver
echo "Making $package_name.zip"
zip -qr $package_name.zip $package_name
rm -rf $package_name

# Calculate SHA sum and size
sha=`shasum -a 256 $package_name.zip | cut -f 1 -d ' '`
size=`/bin/ls -l $package_name.zip | awk '{print $5}'`
echo Size: $size
echo SHA-256: $sha

new_json=package_cytron_m328pb_index.json

echo "Making package_cytron_m328pb_index.json"
cat $srcdir/package/package_cytron_m328pb_index.template.json | \
jq ".packages[0].platforms[0].version = \"$ver\" | \
    .packages[0].platforms[0].url = \"$PKG_URL\" |\
    .packages[0].platforms[0].archiveFileName = \"$package_name.zip\" |\
    .packages[0].platforms[0].checksum = \"SHA-256:$sha\" |\
    .packages[0].platforms[0].size = \"$size\" |\
    .packages[0].platforms[0].help.online = \"$DOC_URL\"" \
    > tmp

cat tmp > $new_json

# merge current json with latest json
set +e
python ../../merge_packages.py $new_json $srcdir/package_cytron_m328pb_index_stable.json >tmp && mv tmp $new_json

# prepare to commit latest stable index.json in this repo
echo -n $M328PB_DEPLOY_KEY > ~/.ssh/m328pb_deploy_b64
base64 --decode --ignore-garbage ~/.ssh/m328pb_deploy_b64 > ~/.ssh/m328pb_deploy
chmod 600 ~/.ssh/m328pb_deploy
cat ~/.ssh/m328pb_deploy
echo -e "Host atmega328pb-board-package\n\tHostname github.com\n\tUser git\n\tStrictHostKeyChecking no\n\tIdentityFile ~/.ssh/m328pb_deploy" >> ~/.ssh/config

cp $new_json ../../../package_cytron_m328pb_index_stable.json

echo "Hello world test" > ../../../hello.txt

popd
popd
