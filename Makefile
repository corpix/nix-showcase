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
tmux                := tmux -2 -f $(root)/.tmux.conf -S $(root)/.tmux
tmux_session        := $(name)

shell_opts = -v nix:/nix:rw                     \
	-v $(root):/chroot                      \
	-e COLUMNS=$(COLUMNS)                   \
	-e LINES=$(LINES)                       \
	-e TERM=$(TERM)                         \
	-e NIX_BUILD_CORES=$(NIX_BUILD_CORES)   \
	-e HOME=/chroot                         \
	-w /chroot                              \
	--hostname localhost                    \
	$(foreach v,$(ports), -p $(v):$(v) )

## macro

define fail
{ echo "error: "$(1) 1>&2; exit 1; }
endef

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
        -f ./container.nix

.PHONY: nix/push/container
nix/push/container: build/container.tar.gz # upload container built by nix
	@# about insecure policy, see: https://github.com/containers/skopeo/issues/394
	@skopeo --insecure-policy                                   \
		copy --dest-creds=$(docker_user):$(docker_password) \
		docker-archive://$(root)/$<                         \
		docker://$(container_namespace)/$(name):$(container_tag)

## env

.PHONY: run/shell
run/shell: # enter development environment with nix-shell
	nix-shell

.PHONY: run/nix/repl
run/nix/repl: # run nix repl for nixpkgs from env
	nix repl '<nixpkgs>'

## dev session

.PHONY: run/tmux/session
run/tmux/session: # start development environment
	@$(tmux) has-session    -t $(tmux_session) && $(call fail,tmux session $(tmux_session) already exists$(,) use: '$(tmux) attach-session -t $(tmux_session)' to attach) || true
	@$(tmux) new-session    -s $(tmux_session) -n console -d
	@$(tmux) select-window  -t $(tmux_session):0

	@if [ -f $(root)/.personal.tmux.conf ]; then             \
		$(tmux) source-file $(root)/.personal.tmux.conf; \
	fi

	@$(tmux) attach-session -t $(tmux_session)

.PHONY: run/tmux/attach
run/tmux/attach: # attach to development session if running
	@$(tmux) attach-session -t $(tmux_session)

.PHONY: run/tmux/kill
run/tmux/kill: # kill development environment
	@$(tmux) kill-session -t $(tmux_session)

#### runners

.PHONY: run/docker/shell
run/docker/shell: # run development environment shell
	@docker run --rm -it                   \
		--log-driver=none              \
		$(shell_opts) nixos/nix:latest \
		nix-shell --run 'exec make run/shell'

.PHONY: run/docker/clean
run/docker/clean: # clean development environment artifacts
	docker volume rm nix

##

.PHONY: clean
clean:: # clean state
	rm -rf result*
	rm -rf build main
	rm -rf .cache/* .local/* .config/* || true
