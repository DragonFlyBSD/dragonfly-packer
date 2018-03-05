# Packer templates for DragonFly BSD

This is a set of scripts and templates for [packer](https://www.packer.io/) to produce Vagrant usable boxes. The boxes will be available [here](https://app.vagrantup.com/dragonflybsd).

Our intention is to have one box per release supported (minor releases included 5.0.1, 5.0.2, ...) and a weekly box for latest (snapshot).

Please bear in mind that this repo contains scripts and templates specific to our build infrastructure and that may not be suitable for your own case, although in anycase **pull requests are welcome** :-)

# References

This templates are loosely in the work from other people:

[b00ga's templates](https://github.com/b00ga/packer-templates)
[brd's templates for FreeBSD](https://github.com/brd/packer-freebsd)
[boxcutter's templates](https://github.com/boxcutter/bsd)

Probably somebody else's ...
