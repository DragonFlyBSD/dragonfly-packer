fmt:
	packer fmt .

build-hammer2:
	packer build \
		-only 'virtualbox-iso.*' \
		-var 'dfly_version=6.4.0' \
		-var 'iso_mirror_location=jp-1' \
		-var 'install_script=dfly_hammer2.sh' \
		-var 'headless=false' \
		.

build-640:
	packer build \
		-only 'virtualbox-iso.*' \
		-var 'dfly_version=6.4.0' \
		-var 'iso_mirror_location=jp-1' \
		-var 'install_script=dfly_hammer_legacy.sh' \
		-var 'headless=false' \
		.
