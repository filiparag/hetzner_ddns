### Building hetzner_ddns for OpenWrt
This is a short introduction on how to build *hetzner_ddns* for OpenWrt (`.ipk`).

#### Sources of information
The hetzner_ddns package is build using the [developer guide|https://openwrt.org/docs/guide-developer/start] for OpenWrt.
Especially the [hello world example|https://openwrt.org/docs/guide-developer/helloworld/start] helps to understand `opkg` package feeds.

Additional information can be found at [procd init scripts|https://openwrt.org/docs/guide-developer/procd-init-scripts] in order to create the `/etc/init.d/hetzner_ddns` service.

#### Build steps
1. Clone *hetzner_ddns* repository: `git clone https://github.com/filiparag/hetzner_ddns`
2. Clone OpenWrt
```shell
# cloning
git clone https://git.openwrt.org/openwrt/openwrt.git source

# checkout the release for which the package should be build for
git checkout <version tag> # i. e. v23.05.5
make distclean
```
3. Now assuming the following directory structure for the next steps:
```shell
.                 # this is your ${YOUR_ROOT_WORKING_DIR}
├── hetzner_ddns  # hetzner_ddns repo
└── openwrt       # openwrt repo
```
4. Create toolchain for cross-compiling (short summary, for more information follow links in "Sources of information"):
```shell
# update to newest feeds
cd openwrt/source
./scripts/feeds update -a
./scripts/feeds install -a

# create config for all architectures
make menuconfig
# add additional binaries to $PATH variable
export PATH=/${YOUR_ROOT_WORKING_DIR}/openwrt/source/staging_dir/host/bin:$PATH
```
5. Prepare `mypackages` directory at `${YOUR_ROOT_WORKING_DIR}` with `mkdir -p mypackages/Network/hetzner_ddns` 
6. Copy files into package directory `cp hetzner_ddns/release/OpenWrt/* mypackages/Network/hetzner_ddns`
7. Create a new `openwrt/source/feeds.conf` for the *hetzner_ddns* package and update feeds
```shell
# add hetzner_ddns to feed
echo "src-link mypackages ${YOUR_ROOT_WORKING_DIR}/mypackages/Network/hetzner_ddns" >> feeds.conf

# update feeds with your package
./scripts/feeds update mypackages
./scripts/feeds install -a -p mypackages
```
8. Build package `make -j$(nproc) package/hetzner_ddns/compile` in `openwrt/source`
9. Copy the created package to your router and install it on OpenWrt with `opkg install hetzner_ddns_*.ipk`


