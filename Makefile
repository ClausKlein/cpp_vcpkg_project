#! Prefer using task with Taskfile.yml, which is a cross-platform replacement for Makefile with better error-handling and syntax.

# Notes:
# - list all the task under PHONY
# - If getting missing separator error, try replacing spaces with tabs.
# - If using Visual Studio, either run the following commands inside the Visual Studio command prompt (vcvarsall) or remove the Ninja generator from the commands.
.PHONY: build test test_release test_install coverage docs format clean

build: release

release:
	cmake --workflow --preset default

debug:
	cmake -S ./ -B ./build -G "Ninja Multi-Config" -DCMAKE_BUILD_TYPE:STRING=Debug -DFEATURE_TESTS:BOOL=OFF
	cmake --build ./build --config Debug

test:
	cmake --workflow --preset developer

test_release_debug:
	cmake -S ./ -B ./build -G "Ninja Multi-Config" -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo -DFEATURE_TESTS:BOOL=ON
	cmake --build ./build --config RelWithDebInfo

	(cd build/my_exe/test && ctest -C RelWithDebInfo --output-on-failure)
	(cd build/my_header_lib/test && ctest -C RelWithDebInfo --output-on-failure)
	(cd build/my_lib/test && ctest -C RelWithDebInfo --output-on-failure)

test_release: release

test_install: release

coverage:
ifeq ($(OS), Windows_NT)
	OpenCppCoverage.exe --export_type cobertura:coverage.xml --cover_children -- $(MAKE) test
else
	$(MAKE) test
	gcovr -j 1 --delete --root ./ --print-summary --xml-pretty --xml coverage.xml ./build --gcov-executable gcov
endif

docs:
	cmake -S ./ -B ./build -G "Ninja Multi-Config" -DCMAKE_BUILD_TYPE:STRING=Debug -DFEATURE_DOCS:BOOL=ON -DFEATURE_TESTS:BOOL=OFF
	cmake --build ./build --target doxygen-docs --config Debug

format:
ifeq ($(OS), Windows_NT)
	pwsh -c '$$files=(git ls-files --exclude-standard); foreach ($$file in $$files) { if ((get-item $$file).Extension -in ".json", ".cpp", ".hpp", ".c", ".cc", ".cxx", ".hxx", ".ixx") { clang-format -i -style=file $$file } }'
else
	git ls-files --exclude-standard | grep -E '\.(json|cpp|hpp|c|cc|cxx|hxx|ixx)$$' | xargs clang-format -i -style=file
endif

clean:
ifeq ($(OS), Windows_NT)
	pwsh -c 'function rmrf($$path) { if (test-path $$path) { rm -r -force $$path }}; rmrf ./build;'
else
	rm -rf ./build
endif
