# Include Nerves-specific packages
include $(sort $(wildcard $(BR2_EXTERNAL)/package/*/*.mk))

# Nerves targets

# NERVES_DEFCONFIG_DIR is used to reference files in configurations
# relative to wherever the _defconfig is stored.
NERVES_DEFCONFIG_DIR = $(dir $(call qstrip,$(BR2_DEFCONFIG)))
export NERVES_DEFCONFIG_DIR

# Pull in any configuration-specific packages
-include $(NERVES_DEFCONFIG_DIR)/external.mk

# Create a system image for use by Bakeware and for creating
# firmware images without Buildroot
system:
	$(BR2_EXTERNAL)/scripts/mksystem.sh $(BR2_NERVES_SYSTEM_NAME)

NERVES_FIRMWARE=$(firstword $(wildcard $(BINARIES_DIR)/*.fw))

# Replace everything on the SDCard with new bits
burn-complete: burn
burn:
	@if [ -e "$(NERVES_FIRMWARE)" ]; then \
		echo "Burning $(NERVES_FIRMWARE)..."; \
		sudo $(HOST_DIR)/usr/bin/fwup -a -i $(NERVES_FIRMWARE) -t complete; \
	else \
		echo "ERROR: No firmware found. Check that 'make' completed successfully"; \
		echo "and that a firmware (.fw) file is in $(BINARIES_DIR)."; \
	fi

# Upgrade the image on the SDCard (app data won't be removed)
# This is usually the fastest way to update an SDCard that's already
# been programmed. It won't update bootloaders, so if something is
# really messed up, burn-complete may be better.
burn-upgrade:
	@if [ -e "$(NERVES_FIRMWARE)" ]; then \
		echo "Upgrading $(NERVES_FIRMWARE)..."; \
		sudo $(HOST_DIR)/usr/bin/fwup -a -i $(NERVES_FIRMWARE) -t upgrade --no-eject; \
		sudo $(HOST_DIR)/usr/bin/fwup -y -a -i /tmp/finalize.fw -t on-reboot; \
		sudo rm /tmp/finalize.fw; \
	else \
		echo "ERROR: No firmware found. Check that 'make' completed successfully"; \
		echo "and that a firmware (.fw) file is in $(BINARIES_DIR)."; \
	fi

help:
	@echo "Nerves System Help"
	@echo "------------------"
	@echo
	@echo "This build directory is configured to create the system described in:"
	@echo
	@echo "$(BR2_DEFCONFIG)"
	@echo
	@echo "Building:"
	@echo "  all                           - Build the current configuration"
	@echo "  burn                          - Burn the most recent build to an SDCard (requires sudo)"
	@echo "  system                        - Build a system image for use with bake"
	@echo "  clean                         - Clean everything"
	@echo
	@echo "Configuration:"
	@echo "  menuconfig                    - Run Buildroot's menuconfig"
	@echo "  linux-menuconfig              - Run menuconfig on the Linux kernel"
	@echo
	@echo "For much more information about the targets in this Makefile, run 'make buildroot-help'"
	@echo "and see the Buildroot documentation."

.PHONY: burn burn-complete burn-upgrade system help
