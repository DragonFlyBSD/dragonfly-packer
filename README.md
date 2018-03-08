# Packer templates for DragonFly BSD

This is a set of scripts and templates for [packer](https://www.packer.io/) to produce Vagrant usable boxes. The boxes will be available [here](https://app.vagrantup.com/dragonflybsd).

Our intention is to have one box per release supported (minor releases included 5.0.1, 5.0.2, ...) and a weekly box for latest (snapshot).

Please bear in mind that this repo contains scripts and templates specific to our build infrastructure and that may not be suitable for your own case, although in anycase **pull requests are welcome** :-)

We will build boxes for the following providers:

- libvirt
- Virtualbox (built-in in Vagrant)
- VMWare (the vagrant-vmware plugin requires a license but you can use [mech](https://github.com/mechboxes/mech))
- Hyper-V (some caveats)

At this moment DragonFly BSD does not have support for any virtualization technology with acceleration so you'll have to run the DragonFly BSD boxes in another OS like Linux Windows or MacOS.

# References

This templates are loosely in the work from other people:

- [b00ga's templates](https://github.com/b00ga/packer-templates)
- [brd's templates for FreeBSD](https://github.com/brd/packer-freebsd)
- [boxcutter's templates](https://github.com/boxcutter/bsd)


Probably somebody else's ...
