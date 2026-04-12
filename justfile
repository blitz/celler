set positional-arguments

here := env_var_or_default("JUST_INVOCATION_DIR", invocation_directory())
base := `pwd`

#@echo "here: {{ here }}"
#@echo "base: {{ base }}"

# List available targets
list:
	@just --list --unsorted

# Run a command with an alternative Nix version
with-nix version *command:
	set -e; \
		hook="$(jq -e -r '.[$version].shellHook' --arg version "{{ version }}" < "$NIX_VERSIONS" || (>&2 echo "Version {{ version }} doesn't exist"; exit 1))"; \
		eval "$hook"; \
		CARGO_TARGET_DIR="{{ base }}/target/nix-{{ version }}" \
		{{ command }}

# (CI) Run unit tests
ci-unit-tests matrix:
	#!/usr/bin/env bash
	set -euxo pipefail

	system=$(nix-instantiate --eval -E 'builtins.currentSystem')
	tests=$(nix build .#internalMatrix."$system".\"{{ matrix }}\".attic-tests --no-link --print-out-paths -L)
	find "$tests/bin" -exec {} \;

# (CI) Run rustfmt check
ci-rustfmt:
	cargo fmt --check

# (CI) Build and push images
ci-build-and-push-images *args:
	.ci/build-and-push-images.sh {{ args }}
