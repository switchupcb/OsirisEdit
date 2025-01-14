VERSION = 1.1

FLAGS = -Wall -Wextra -Wno-unused-parameter -g -Wno-unused -O3 -march=nocona -ffast-math \
	-DVERSION=$(VERSION) -DPFFFT_SIMD_DISABLE \
	-I. -Iext -Iext/imgui -Idep/include -Idep/include/SDL2
CFLAGS =
CXXFLAGS = -std=c++11
LDFLAGS =


SOURCES = \
	ext/pffft/pffft.c \
	ext/lodepng/lodepng.cpp \
	ext/imgui/imgui.cpp \
	ext/imgui/imgui_draw.cpp \
	ext/imgui/imgui_demo.cpp \
	ext/imgui/examples/sdl_opengl2_example/imgui_impl_sdl.cpp \
	$(wildcard src/*.cpp)


# OS-specific
include Makefile-arch.inc
ifeq ($(ARCH),lin)
	# Linux
	FLAGS += -DARCH_LIN $(shell pkg-config --cflags gtk+-2.0)
	LDFLAGS += -static-libstdc++ -static-libgcc \
		-lGL -lpthread \
		-Ldep/lib -lSDL2 -lsamplerate -lsndfile -ljansson -lcurl \
		-lgtk-x11-2.0 -lgobject-2.0
	SOURCES += ext/osdialog/osdialog_gtk2.c
else ifeq ($(ARCH),mac)
	# Mac
	FLAGS += -DARCH_MAC \
		-mmacosx-version-min=10.7
	CXXFLAGS += -stdlib=libc++
	LDFLAGS += -mmacosx-version-min=10.7 \
		-stdlib=libc++ -lpthread \
		-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo \
		-Ldep/lib -lSDL2 -lsamplerate -lsndfile -ljansson -lcurl
	SOURCES += ext/osdialog/osdialog_mac.m
else ifeq ($(ARCH),win)
	# Windows
	FLAGS += -DARCH_WIN
	LDFLAGS += \
		-Ldep/lib -lmingw32 -lSDL2main -lSDL2 -lsamplerate -lsndfile -ljansson -lcurl \
		-lopengl32 -mwindows
	SOURCES += ext/osdialog/osdialog_win.c
	OBJECTS += info.o
info.o: info.rc
	windres $^ $@
endif


.DEFAULT_GOAL := build
build: OsirisEdit

run: OsirisEdit
	LD_LIBRARY_PATH=dep/lib ./OsirisEdit

debug: OsirisEdit
ifeq ($(ARCH),mac)
	lldb ./OsirisEdit
else
	gdb -ex 'run' ./OsirisEdit
endif


OBJECTS += $(SOURCES:%=build/%.o)


OsirisEdit: $(OBJECTS)
	$(CXX) -o $@ $^ $(LDFLAGS)

clean:
	rm -frv $(OBJECTS) OsirisEdit dist


.PHONY: dist
dist: OsirisEdit
	mkdir -p dist/OsirisEdit
	cp -R banks dist/OsirisEdit
	cp LICENSE* dist/OsirisEdit
	cp doc/manual.pdf dist/OsirisEdit
ifeq ($(ARCH),lin)
	cp -R logo*.png fonts catalog dist/OsirisEdit
	cp OsirisEdit OsirisEdit.sh dist/OsirisEdit
	cp dep/lib/libSDL2-2.0.so.0 dist/OsirisEdit
	cp dep/lib/libsamplerate.so.0 dist/OsirisEdit
	cp dep/lib/libsndfile.so.1 dist/OsirisEdit
	cp dep/lib/libjansson.so.4 dist/OsirisEdit
	cp dep/lib/libcurl.so.4 dist/OsirisEdit
else ifeq ($(ARCH),mac)
	mkdir -p dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	mkdir -p dist/OsirisEdit/OsirisEdit.app/Contents/Resources
	cp Info.plist dist/OsirisEdit/OsirisEdit.app/Contents
	cp OsirisEdit dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	cp -R logo*.png logo.icns fonts catalog dist/OsirisEdit/OsirisEdit.app/Contents/Resources
	# Remap dylibs in executable
	otool -L dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	cp dep/lib/libSDL2-2.0.0.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	install_name_tool -change $(PWD)/dep/lib/libSDL2-2.0.0.dylib @executable_path/libSDL2-2.0.0.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	cp dep/lib/libsamplerate.0.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	install_name_tool -change $(PWD)/dep/lib/libsamplerate.0.dylib @executable_path/libsamplerate.0.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	cp dep/lib/libsndfile.1.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	install_name_tool -change $(PWD)/dep/lib/libsndfile.1.dylib @executable_path/libsndfile.1.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	cp dep/lib/libjansson.4.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	install_name_tool -change $(PWD)/dep/lib/libjansson.4.dylib @executable_path/libjansson.4.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	cp dep/lib/libcurl.4.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS
	install_name_tool -change $(PWD)/dep/lib/libcurl.4.dylib @executable_path/libcurl.4.dylib dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
	otool -L dist/OsirisEdit/OsirisEdit.app/Contents/MacOS/OsirisEdit
else ifeq ($(ARCH),win)
	cp -R logo*.png fonts catalog dist/OsirisEdit
	cp OsirisEdit.exe dist/OsirisEdit
	cp /mingw32/bin/libgcc_s_dw2-1.dll dist/OsirisEdit
	cp /mingw32/bin/libwinpthread-1.dll dist/OsirisEdit
	cp /mingw32/bin/libstdc++-6.dll dist/OsirisEdit
	cp dep/bin/SDL2.dll dist/OsirisEdit
	cp dep/bin/libsamplerate-0.dll dist/OsirisEdit
	cp dep/bin/libsndfile-1.dll dist/OsirisEdit
	cp dep/bin/libjansson-4.dll dist/OsirisEdit
	cp dep/bin/libcurl-4.dll dist/OsirisEdit
endif
	cd dist && zip -9 -r OsirisEdit-$(VERSION)-$(ARCH).zip OsirisEdit


# SUFFIXES:

build/%.c.o: %.c
	@mkdir -p $(@D)
	$(CC) $(FLAGS) $(CFLAGS) -c -o $@ $<

build/%.cpp.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(FLAGS) $(CXXFLAGS) -c -o $@ $<

build/%.m.o: %.m
	@mkdir -p $(@D)
	$(CC) $(FLAGS) $(CFLAGS) -c -o $@ $<
