DOCKER_ID_ORGANIZATION=setmyinfo
DOCKER_PROJECT_NAME=$(basename "$(pwd)")
DOCKER_BUILD_ARGS=""
DOCKER_FILE=Dockerfile

docker_prepare() {
    :
}

docker_build() {
    :
}

docker_push() {
    :
}

dockerPrepare() {
    docker_prepare
}

dockerBuild() {
    docker_build || return
    [ -f "${DOCKER_FILE}" ] || { echo "No ${DOCKER_FILE}, no image to build"; return 0; }
    build_image && \
    build_latest_tag && \
    build_inspect_latest_tag && \
    build_show_images
}

dockerPush() {
    docker_push || return
    [ -f "${DOCKER_FILE}" ] || { echo "No ${DOCKER_FILE}, no image to push"; return 0; }
    build_login && \
    build_push
}

build_image() {
    echo "Building image ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION}"
    VERSION="${DOCKER_PROJECT_VERSION}"
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    VCS_REF=$(git rev-parse --short HEAD)
    export VERSION BUILD_DATE VCS_REF ${DOCKER_BUILD_ARGS}
    for BUILD_ARG in ${DOCKER_BUILD_ARGS}; do
        if [ -z "$(printenv ${BUILD_ARG})" ]; then
            echo "Build argument ${BUILD_ARG} is not set"
            return 1
        fi
    done
    BUILD_ARGS=""
    for BUILD_ARG in VERSION BUILD_DATE VCS_REF ${DOCKER_BUILD_ARGS}; do
        echo "${BUILD_ARG}=$(printenv ${BUILD_ARG})"
        BUILD_ARGS="${BUILD_ARGS} --build-arg ${BUILD_ARG}"
    done
    BUILDKIT_PROGRESS=plain docker build ${BUILD_ARGS} -f ${DOCKER_FILE} -t ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION} .
}

build_latest_tag() {
    echo "Setting latest tag"
    docker image tag ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION} ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:latest
}

build_inspect_latest_tag() {
    echo "Inspecting latest tag"
    docker inspect ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:latest
}

build_show_images() {
    echo "Getting image list"
    docker image list
}

build_login() {
    echo "Doing Docker Hub login"
    docker login
}

build_push() {
    echo "Start pushing image"
    docker image push ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:latest && \
    docker image push ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION}
}
