# Build Terraform Binary
The fyre plugin is a IBM intenal plugin, for to build it, need export 2 environments:
```
export IBM_GITHUB_USER=
export IBM_GITHUB_TOKEN=
```

XC_ARCH=${XC_ARCH:-"ppc64le amd64 s390x"}
XC_OS=${XC_OS:-"linux darwin"}

PLUGIN=${PLUGIN:-false}
PROVIDERS=${PROVIDERS:-"null template random tls local openstack vsphere"}
Run command `./build.sh`
