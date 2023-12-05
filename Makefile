fmt:
	packer fmt .

build-640:
	packer build -var-file=variables.640.pkrvars.hcl .
