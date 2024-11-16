### Building hetzner_ddns for OpenWrt
This is a short introduction on how to build *hetzner_ddns* for OpenWrt (`.ipk`).

#### Sources of information
The hetzner-ddns package is build using the [developer guide|https://openwrt.org/docs/guide-developer/start] for OpenWrt.
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
3. Create toolchain for cross-compiling (short summary, for more information follow links in "Sources of information"):
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
4. Directory structure looks like this now:
```shell
.                 # this is your ${YOUR_ROOT_WORKING_DIR}
├── hetzner_ddns  # hetzner_ddns repo
└── openwrt       # openwrt repo
```
5. Create a new `openwrt/source/feeds.conf` for the *hetzner-ddns* package and update feeds
```shell
# add hetzner-ddns to feed
echo "src-link mypackages ${YOUR_ROOT_WORKING_DIR}/hetzner_ddns/release" >> feeds.conf

# update feeds with your package
./scripts/feeds update mypackages
./scripts/feeds install -a -p mypackages

# choose Network -> hetzner_ddns to compile in menuconfig
make menuconfig
```
6. Build package `make -j$(nproc) package/OpenWrt/compile` within `openwrt/source` directory
7. Copy the created package to your router and install it on OpenWrt with `opkg install hetzner-ddns_*.ipk`


