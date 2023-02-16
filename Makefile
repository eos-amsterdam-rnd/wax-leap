DEV_VERSION=v3.1.3wax01
DEV_DOCKER_IMAGE=waxteam/waxdev:$(DEV_VERSION)
DEV_DOCKER_CONTAINER=waxblockchain-dev
DEV_DOCKER_COMMON=-v `pwd`:/opt/wax-blockchain \
			--name $(DEV_DOCKER_CONTAINER) -w /opt/wax-blockchain $(DEV_DOCKER_IMAGE)

nproc := $(shell grep -c ^processor /proc/cpuinfo)

get-latest:
	docker pull $(DEV_DOCKER_IMAGE)

.PHONY: safe-git-path
safe-git-path:
	git config --global --add safe.directory `pwd`

build: safe-git-path
	-mkdir build && \
	cd build && \
	cmake -DCMAKE_C_COMPILER=gcc-8 -DCMAKE_CXX_COMPILER=g++-8 -DCMAKE_PREFIX_PATH="${HOME}/boost1.79;/usr/lib/llvm-7/" -DCMAKE_BUILD_TYPE=Release .. && \
	cd ..

.PHONY: compile
compile: build
	cd build && make -j$(nproc) package

.PHONY: clean
clean:
	-rm -rf build

.PHONY: test
test: compile
	cd build && ctest -j "$(nproc)" -LE _tests

.PHONY: test-wasm
test-wasm: compile
	cd build && ctest -j "$(nproc)" -L wasm_spec_tests

.PHONY: test-serial
test: compile
	cd build && ctest -L "nonparallelizable_tests"

.PHONY: test-integration
test-integration: compile
	cd build && ctest -L "long_running_tests"

.PHONY:dev-docker-stop
dev-docker-stop:
	-docker rm -f $(DEV_DOCKER_CONTAINER)

.PHONY:dev-docker-start
dev-docker-start: dev-docker-stop get-latest
	docker run -it $(DEV_DOCKER_COMMON) bash

# Useful for travis CI
.PHONY:dev-docker-all
dev-docker-all: dev-docker-stop get-latest
	docker run $(DEV_DOCKER_COMMON) bash -c "make clean test"