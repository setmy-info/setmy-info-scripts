dockerPrepare() {
    docker_prepare
}

dockerBuild() {
    docker_build
    build_image && \
    build_latest_tag && \
    build_show_images && \
    build_login && \
    build_push
}

build_image() {
    echo "Building image ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION}"
    export BUILDKIT_PROGRESS=plain
    export DOCKER_BUILDKIT=0
    docker build -t ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION} .
    export DOCKER_BUILDKIT="${DOCKER_BUILDKIT}"
    export BUILDKIT_PROGRESS="${BUILDKIT_PROGRESS}"
    docker build -t ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION} .
    docker image list
}

build_latest_tag() {
    echo "Setting latest tag"
    docker image tag ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION} ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:latest
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
    docker image push ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:latest
    docker image push ${DOCKER_ID_ORGANIZATION}/${DOCKER_PROJECT_NAME}:${DOCKER_PROJECT_VERSION}
}
