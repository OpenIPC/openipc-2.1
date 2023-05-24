BR_VER = 2021.02.12
BR_LINK = https://github.com/buildroot/buildroot/archive/refs/tags
BR_MAKE = $(MAKE) -C buildroot-$(BR_VER) BR2_EXTERNAL=$(PWD)/general O=$(PWD)/output
BR_FILE = /tmp/download/buildroot-$(BR_VER).tar.gz

ifdef BOARD
	CONFIG = $(shell find br-ext-chip-*/configs -type f | grep -m1 $(BOARD))
endif

ifeq ($(CONFIG),)
	CONFIG = $(error variable BOARD must be defined to initialize build)
else
	ifneq ($(shell grep GCC_VERSION_12 $(CONFIG)),)
		BR_VER = 2023.02
	endif
endif

.PHONY: all clean defconfig distclean help prepare toolname

help:
	@printf "BR-OpenIPC usage:\n \
	- make clean - remove defconfig and target folder\n \
	- make distclean - remove buildroot and output folder\n \
	- make list-configs - show available device configurations\n \
	- make all BOARD=<config> - builds the selected device\n\n"

all: defconfig
	@$(BR_MAKE) all

br-%: defconfig
	@$(BR_MAKE) $(subst br-,,$@)

defconfig: prepare
	@$(BR_MAKE) BR2_DEFCONFIG=$(PWD)/$(CONFIG) defconfig

toolname: prepare
	@general/scripts/show_toolchains.sh $(CONFIG) $(BR_VER)

prepare:
	@mkdir -p /tmp/download
	@test -e $(BR_FILE) || wget -c -q $(BR_LINK)/$(BR_VER).tar.gz -O $(BR_FILE)
	@test -e buildroot-$(BR_VER) || tar -xf $(BR_FILE) -C $(PWD)

buildroot-version:
	@echo $(BR_VER)

clean:
	@rm -rf output/target output/.config

distclean:
	@rm -rf output buildroot-$(BR_VER) $(BR_FILE)

list-configs:
	@ls -1 br-ext-chip-*/configs
