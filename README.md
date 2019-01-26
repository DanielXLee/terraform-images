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
     [image]               Build terraform and plugin docker images
     [push]                Push terraform and plugin docker images
     [multi]               Build terraform and plugin multiple arch docker images

Examples:
Build binary
  ./build.sh -c bin
Build image
  ./build.sh -c image
Push image
  ./build.sh -c push
Build multi image
  ./build.sh -c multi
Build all
  ./build.sh
```
