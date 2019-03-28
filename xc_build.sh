#!/usr/bin/env bash
#
# This script builds the application from source for multiple platforms.

function build() {
  # Delete the old dir
  echo "==> Removing old directory..."
  rm -f bin/*
  rm -rf pkg/*
  mkdir -p bin/

  if ! which gox > /dev/null; then
      echo "==> Installing gox..."
      go get -u github.com/mitchellh/gox
  fi

  # instruct gox to build statically linked binaries
  export CGO_ENABLED=0

  # Ensure all remote modules are downloaded and cached before build so that
  # the concurrent builds launched by gox won't race to redundantly download them.
  go mod download

  # Build!
  echo "==> Building..."
  gox \
      -os="${XC_OS}" \
      -arch="${XC_ARCH}" \
      -osarch="${XC_EXCLUDE_OSARCH}" \
      -output "${OUTPUT}" .
  cp -r pkg ${GOPATH}
}

function build_terraform () {
  # Get the terraform source code.
  echo "Build terraform binary"
  go get -u github.com/hashicorp/terraform
  # Change into that directory
  pushd "${GOPATH}/src/github.com/hashicorp/terraform"
  git checkout v${TERRAFORM_VERSION}
  OUTPUT="pkg/{{.OS}}_{{.Arch}}/${PWD##*/}"
  build
  popd
}

function build_terraform_plugins () {
  # Get the public providers source code.
  echo "Build public plugins"
  for provider in $PROVIDERS; do
    go get -u github.com/terraform-providers/terraform-provider-${provider}
    # Change into that directory
    pushd "${GOPATH}/src/github.com/terraform-providers/terraform-provider-${provider}"
    OUTPUT="pkg/plugins/{{.OS}}_{{.Arch}}/${PWD##*/}"
    build
    popd
  done

  echo "Build fyre plugin"
  if [[ "X${IBM_GITHUB_USER}" != "X" && "X${IBM_GITHUB_TOKEN}" != "X" ]]; then
    go get github.com/tmc/scp
    cd ${GOPATH}/src;git clone https://${IBM_GITHUB_USER}:${IBM_GITHUB_TOKEN}@github.ibm.com/bhwarren/terraform-fyre.git
    pushd ${GOPATH}/src/terraform-fyre
    git checkout v1.1.1
    OUTPUT="pkg/plugins/{{.OS}}_{{.Arch}}/terraform-provider-fyre"
    build
    popd
  else
    echo "IBM_GITHUB_USER or IBM_GITHUB_TOKEN does not existing, ignore fyre plugin build."
  fi
}

#----------------------------------- Main --------------------------------------
# Determine the arch/os combos we're building for
XC_ARCH=${XC_ARCH:-"ppc64le amd64 s390x"}
XC_OS=${XC_OS:-"linux darwin"}
XC_EXCLUDE_OSARCH="!darwin/arm !darwin/386"
PLUGIN=${PLUGIN:-}
PROVIDERS=${PROVIDERS:-"null template random tls local openstack vsphere"}

if [[ "$PLUGIN" == "true" ]]; then
  build_terraform_plugins
elif [[ "$PLUGIN" == "false" ]]; then
  build_terraform
else
  build_terraform
  build_terraform_plugins
fi
