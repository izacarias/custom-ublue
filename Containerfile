ARG BASE_IMAGE_NAME="silverblue"
ARG BASE_IMAGE_TAG="44"
ARG BASE_IMAGE_REPO="quay.io/fedora-ostree-desktops"
ARG BASE_IMAGE_REF="${BASE_IMAGE_REPO}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY /build_files /build_files
COPY /system_files /system_files

# Base Image
FROM ${BASE_IMAGE_REF} AS base

# Customizations

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/build_files,target=/ctx/build_files \
    --mount=type=bind,from=ctx,source=/system_files,target=/ctx/system_files \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/boot \
    bash -euo pipefail -c ' \
        dnf5 config-manager setopt keepcache=1 && \
        dnf5 config-manager setopt install_weak_deps=0 && \
        /ctx/build_files/build.sh \
    '

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt


CMD ["/sbin/init"]


## Verify final image and contents are correct.
RUN bootc container lint