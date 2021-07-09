# OsirisEdit

The modified wavetable and bank editor for the Osiris Eurorack synthesizer modules.

### Building

Make dependencies with

	cd dep
	make

Clone the in-source dependencies.

	cd ..
	git submodule update --init --recursive

Compile the program. The Makefile will automatically detect your operating system.

	make

Launch the program.

	./OsirisEdit

You can even try your luck with building the polished distributable. Although this method is unsupported, it may work with some tweaks to the Makefile.

	make dist
