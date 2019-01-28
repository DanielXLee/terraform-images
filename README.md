# Build Terraform Binary
## Requirement environment variables
1. Build fyre plugin(optional)

The fyre plugin is a IBM internal plugin, for to build it, need export 2 environments:
```
export IBM_GITHUB_USER=
export IBM_GITHUB_TOKEN=
```
2. Customer build os and arch

Default os(XC_OS): "linux darwin"

Default arch(XC_ARCH): "ppc64le amd64 s390x"
```
export XC_ARCH=amd64
export XC_OS=linux
```
3. Disable build plugins
```
export PLUGIN=false
```
4. Customer plugin list

Default: "null template random tls local openstack vsphere"
```
export PROVIDERS="null template random tls local openstack vsphere"
```
### Build binary and images
```
Usage: build.sh <[Option]>

Options:
  -h help                  Display this help and exit
  -c command               Run command (bin, image, push, multi)
     [bin]                 Build terraform and plugin binary
     [pkg]                 Build terraform and plugin zip package
     [image]               Build terraform and plugin docker images
     [push]                Push terraform and plugin docker images
     [multi]               Build terraform and plugin multiple arch docker images

Examples:
Build binary
  ./build.sh -c bin
Build zip package
  ./build.sh -c pkg
Build image
  ./build.sh -c image
Push image
  ./build.sh -c push
Build multi image
  ./build.sh -c multi
Build all
  ./build.sh

```
Example 1. Build terraform core binary
```
export PLUGIN=false
export TERRAFORM_VERSION=0.11.11 # Optional, default is 0.11.10
./build.sh -c bin

pkg
├── darwin_amd64
│   └── terraform
├── linux_amd64
│   └── terraform
├── linux_ppc64le
│   └── terraform
└── linux_s390x
    └── terraform
```

Example 2. Build `aws` plugin on os `linux` and arch `amd64 ppc64le s390x`

```
export PLUGIN=true
export PROVIDERS=aws
export XC_ARCH="amd64 ppc64le s390x"
export XC_OS=linux
./build.sh -c bin

pkg/
└── plugin
    ├── linux_amd64
    │   └── terraform-provider-aws
    ├── linux_ppc64le
    │   └── terraform-provider-aws
    └── linux_s390x
        └── terraform-provider-aws
```
