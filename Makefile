# Include makefile config
include config.mk

# Token lib generation
TLIST = common/tokenize.list
THEAD = common/tokenize.h
TSRC  = common/tokenize.c

SRCS  = $(filter-out $(TSRC),$(wildcard *.c) $(wildcard common/*.c) $(wildcard clib/*.c) $(wildcard clib/soup/*.c) $(wildcard widgets/*.c)) $(TSRC)
HEADS = $(wildcard *.h) $(wildcard common/*.h) $(wildcard widgets/*.h) $(wildcard clib/*.h) $(wildcard clib/soup/*.h) $(THEAD) globalconf.h
OBJS  = $(foreach obj,$(SRCS:.c=.o),$(obj))

all: options newline luakit luakit.1

options:
	@echo luakit build options:
	@echo "CC           = $(CC)"
	@echo "LUA_PKG_NAME = $(LUA_PKG_NAME)"
	@echo "CFLAGS       = $(CFLAGS)"
	@echo "CPPFLAGS     = $(CPPFLAGS)"
	@echo "LDFLAGS      = $(LDFLAGS)"
	@echo "PREFIX       = $(PREFIX)"
	@echo "DESTDIR      = $(DESTDIR)"
	@echo "MANDIR       = $(MANDIR)"
	@echo "DOCDIR       = $(DOCDIR)"
	@echo
	@echo build targets:
	@echo "SRCS  = $(SRCS)"
	@echo "HEADS = $(HEADS)"
	@echo "OBJS  = $(OBJS)"

$(THEAD) $(TSRC): $(TLIST)
	./build-utils/gentokens.lua $(TLIST) $@

globalconf.h: globalconf.h.in
	sed 's#LUAKIT_INSTALL_PATH .*#LUAKIT_INSTALL_PATH "$(PREFIX)/share/luakit"#' globalconf.h.in > globalconf.h

$(OBJS): $(HEADS) config.mk

.c.o:
	@echo $(CC) -c $< -o $@
	@$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

widgets/webview.o: $(wildcard widgets/webview/*.c)

luakit: $(OBJS)
	@echo $(CC) -o $@ $(OBJS)
	@$(CC) -o $@ $(OBJS) $(LDFLAGS)

luakit.1: luakit
	@echo help2man -N -o $@ ./$<
	help2man -N -o $@ ./$<

apidoc: luadoc/luakit.lua
	mkdir -p apidocs
	luadoc --nofiles -d apidocs luadoc/* lib/*

doc: globalconf.h $(THEAD) $(TSRC)
	doxygen -s luakit.doxygen

clean:
	rm -rf apidocs doc luakit $(OBJS) $(TSRC) $(THEAD) globalconf.h luakit.1

install: luakit
	install -d $(DESTDIR)$(PREFIX)/share/luakit/
	install -d $(DESTDIR)$(DOCDIR)
	install -m644 README.md AUTHORS COPYING* $(DESTDIR)$(DOCDIR)
	cp -r lib $(DESTDIR)$(PREFIX)/share/luakit/
	chmod 755 $(DESTDIR)$(PREFIX)/share/luakit/lib/
	chmod 755 $(DESTDIR)$(PREFIX)/share/luakit/lib/lousy/
	chmod 755 $(DESTDIR)$(PREFIX)/share/luakit/lib/lousy/widget/
	chmod 644 $(DESTDIR)$(PREFIX)/share/luakit/lib/*.lua
	chmod 644 $(DESTDIR)$(PREFIX)/share/luakit/lib/lousy/*.lua
	chmod 644 $(DESTDIR)$(PREFIX)/share/luakit/lib/lousy/widget/*.lua
	install -d $(DESTDIR)$(PREFIX)/bin
	install luakit $(DESTDIR)$(PREFIX)/bin/luakit
	install -d $(DESTDIR)/etc/xdg/luakit/
	install config/*.lua $(DESTDIR)/etc/xdg/luakit/
	chmod 644 $(DESTDIR)/etc/xdg/luakit/*.lua
	install -d $(DESTDIR)/usr/share/pixmaps
	install extras/luakit.png $(DESTDIR)/usr/share/pixmaps/
	install -d $(DESTDIR)/usr/share/applications
	install -m0644 extras/luakit.desktop $(DESTDIR)/usr/share/applications/
	install -d $(DESTDIR)$(MANDIR)/man1/
	install -m644 luakit.1 $(DESTDIR)$(MANDIR)/man1/

pkgdir:
	mkdir -p /dev/shm/pkg

slackpkg: pkgdir
	make $(MAKEOPTS) $(DESTDIR) DEVELOPMENT_PATHS=0 all luakit.1
	rm -r $(DESTDIR) && mkdir -p $(DESTDIR) && make $(MAKEOPTS) $(DESTDIR) DEVELOPMENT_PATHS=0 install
	cd $(DESTDIR) && makepkg -l y -c n /tmp/luakit-$(shell git id)-$(ARCH)-1jet.tgz
	sudo removepkg $(shell find /var/log/packages/ -name "luakit*" -exec basename {} \;)
	sudo installpkg /tmp/luakit-$(shell git id)-$(ARCH)-1jet.tgz

uninstall:
	rm -rf $(DESTDIR)$(PREFIX)/bin/luakit $(DESTDIR)$(PREFIX)/share/luakit $(DESTDIR)$(MANDIR)/man1/luakit.1
	rm -rf $(DESTDIR)/usr/share/applications/luakit.desktop $(DESTDIR)/usr/share/pixmaps/luakit.png

lunit:
	git clone git://repo.or.cz/lunit.git

run-tests: luakit lunit
	@./luakit -c tests/lunit-run.lua tests/test_*.lua

newline: options;@echo
.PHONY: all clean options install newline apidoc doc
