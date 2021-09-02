.DEFAULT_GOAL := all

root := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

## parameters

name                 = showcase
group                = nix
remote               = gitlab.example.com
namespace            = $(remote)/$(group)
version             ?= development
container_namespace ?= $(remote):5050/$(group)/$(name)
container_tag       ?= latest
docker_user         ?=
docker_password     ?=

##

.PHONY: help
help: # print defined targets and their comments
	@grep -Po '^[a-zA-Z%_/\-\s]+:+(\s.*$$|$$)' Makefile \
		| sort                                      \
		| sed 's|:.*#|#|;s|#\s*|#|'                 \
		| column -t -s '#' -o ' | '

### releases

.PHONY: nix/build/container
nix/build/container:: build/container.tar.gz # build container with nix (in userspace)
build/container.tar.gz::
	nix build -o $@                            \
        --argstr name       $(name)                \
        --argstr namespace  $(container_namespace) \
        --argstr version    $(version)             \
        --argstr tag        $(container_tag)       \
        -f ./default.nix

.PHONY: nix/push/container
nix/push/container: build/container.tar.gz # upload container built by nix
	@# about insecure policy, see: https://github.com/containers/skopeo/issues/394
	@skopeo --insecure-policy                                   \
		copy --dest-creds=$(docker_user):$(docker_password) \
		docker-archive://$(root)/$<                         \
		docker://$(container_namespace)/$(name):$(container_tag)
