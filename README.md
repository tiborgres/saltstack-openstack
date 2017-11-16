# saltstack-openstack

Games with OpenStack installation on local Vagrant machines.

This Github repo has been created just for games with installation of OpenStack components and is not supposed to be used in production.
So the passwords inside the pillar data files are not real in production but just only for these games :)

Installation of these components:
- controller
- compute
- block
- object

You must edit the `Vagrantfile`, `top.sls` files in `/srv/salt` and `/srv/pillar` according to your (customised) setup.

All things in this repo are under development and just for learning/leisure purposes :)
