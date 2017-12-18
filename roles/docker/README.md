Docker Engine Role
===================

Install Docker Engine (recipe for EC3)

Role Variables
--------------

The variables that can be passed to this role and a brief description about them are as follows.

	docker_mirror_protocol: "http"
	docker_mirror_port: 5000
	docker_opts: ""

Example Playbook
----------------
```
  - hosts: server
  roles:
  - { role: 'docker' }
```
```
  - hosts: client
  roles:
  - { role: 'docker' }
```
