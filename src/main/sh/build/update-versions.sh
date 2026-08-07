#!/bin/sh

NEW_VERSION="${1:?Usage: update-versions.sh <new-version>  (e.g. 0.108.0)}"

MAJOR=$(printf '%s' "${NEW_VERSION}" | cut -d. -f1)
MINOR=$(printf '%s' "${NEW_VERSION}" | cut -d. -f2)
PATCH=$(printf '%s' "${NEW_VERSION}" | cut -d. -f3)

sed -i "s/\(SET (PROJECT_VERSION_MAJOR *\)[0-9]*/\1${MAJOR}/" CMakeLists.txt
sed -i "s/\(SET (PROJECT_VERSION_MINOR *\)[0-9]*/\1${MINOR}/" CMakeLists.txt
sed -i "s/\(SET (PROJECT_VERSION_PATCH *\)[0-9]*/\1${PATCH}/" CMakeLists.txt

sed -i "s/SCRIPTS_VERSION=[0-9][0-9.]*/SCRIPTS_VERSION=${NEW_VERSION}/g" README.md

sed -i "s/^\(PROJECT_NUMBER *=\) *[0-9][0-9.]*/\1 ${NEW_VERSION}/" Doxyfile

sed -i "s/setmy-info-scripts-[0-9][0-9.]*\.noarch/setmy-info-scripts-${NEW_VERSION}.noarch/g" Dockerfile

sed -i "s/export PROJECT_VERSION=\"[0-9][0-9.]*\"/export PROJECT_VERSION=\"${NEW_VERSION}\"/" src/main/sh/build/packages-build.sh

sed -i "/smi-version/s/ \"[0-9][0-9.]*\"/ \"${NEW_VERSION}\"/" src/main/sh/build/check-files.sh

sed -i "s/AppVersion=[0-9][0-9.]*/AppVersion=${NEW_VERSION}/" setup.iss
