
PROTO		= $(PWD)/proto
PREFIX		= /opt/irssi-xmpp

IRSSI_VERSION	= 0.8.17
XMPP_VERSION	= 0.53

PKG_INFO	= /opt/local/sbin/pkg_info

.PHONY: all
all: \
	0-irssi-stamp \
	0-loudmouth-stamp \
	0-irssi-xmpp-stamp

##### FILE DOWNLOADS

.PHONY: downloads
downloads: \
    downloads/loudmouth-1.4.3.tar.gz \
    downloads/irssi-$(IRSSI_VERSION).tar.gz \
    downloads/irssi-xmpp-$(XMPP_VERSION).tar.gz

downloads/loudmouth-1.4.3.tar.gz:
	@mkdir -p `dirname $@`
	curl -kL \
		http://ftp.gnome.org/pub/GNOME/sources/loudmouth/1.4/loudmouth-1.4.3.tar.gz \
		> $@

downloads/irssi-xmpp-$(XMPP_VERSION).tar.gz:
	@mkdir -p `dirname $@`
	curl -kL \
		http://cybione.org/~irssi-xmpp/files/irssi-xmpp-$(XMPP_VERSION).tar.gz \
		> $@

downloads/irssi-$(IRSSI_VERSION).tar.gz:
	@mkdir -p `dirname $@`
	curl -kL \
		https://github.com/irssi-import/irssi/releases/download/$(IRSSI_VERSION)/irssi-$(IRSSI_VERSION).tar.gz \
		> $@

##### PACKAGE CHECKS

0-package-stamp:
	@echo "*** CHECKING FOR GNUTLS"
	$(PKG_INFO) gnutls >/dev/null 2>&1 || \
		(echo "ATTN: you should ... pkgin in gnutls" >&2 && exit 1)
	@echo "*** CHECKING FOR GLIB2"
	$(PKG_INFO) glib2 >/dev/null 2>&1 || \
		(echo "ATTN: you should ... pkgin in glib2" >&2 && exit 1)
	@echo "*** CHECKING FOR PKG-CONFIG"
	$(PKG_INFO) pkg-config >/dev/null 2>&1 || \
		(echo "ATTN: you should ... pkgin in pkg-config" >&2 && exit 1)
	touch $@
	@echo "*** DONE WITH PACKAGE CHECKS"

##### IRSSI

irssi-$(IRSSI_VERSION)/configure: downloads/irssi-$(IRSSI_VERSION).tar.gz
	@echo "*** EXTRACTING IRSSI"
	tar xvfz downloads/irssi-$(IRSSI_VERSION).tar.gz
	rm -f irssi-$(IRSSI_VERSION)/config.status
	cd irssi-$(IRSSI_VERSION) && patch -p1 -i ../patches/irssi.multiline.diff
	[[ -f irssi-$(IRSSI_VERSION)/configure ]] && \
		touch irssi-$(IRSSI_VERSION)/configure

irssi-$(IRSSI_VERSION)/config.status: 0-package-stamp irssi-$(IRSSI_VERSION)/configure
	@echo "*** CONFIGURING IRSSI"
	export LDFLAGS="-R$(PREFIX)/lib" && \
	cd irssi-$(IRSSI_VERSION) && \
		./configure --prefix=$(PREFIX)

0-irssi-stamp: 0-package-stamp irssi-$(IRSSI_VERSION)/config.status
	@echo "*** BUILDING IRSSI"
	cd irssi-$(IRSSI_VERSION) && \
		make install DESTDIR=$(PROTO)
	touch $@
	@echo "*** DONE WITH IRSSI"

##### LOUDMOUTH

loudmouth-1.4.3/config.status: loudmouth-1.4.3/configure
	@echo "*** CONFIGURING LOUDMOUTH"
	export LIBGNUTLS_CONFIG=$$PWD/bin/libgnutls-config && \
		cd loudmouth-1.4.3 && \
		./configure --prefix=$(PREFIX)

loudmouth-1.4.3/configure: 0-package-stamp downloads/loudmouth-1.4.3.tar.gz
	@echo "*** EXTRACTING LOUDMOUTH"
	tar xvfz downloads/loudmouth-1.4.3.tar.gz
	rm -f loudmouth-1.4.3/config.status
	[[ -f loudmouth-1.4.3/configure ]] && \
		touch loudmouth-1.4.3/configure
	@echo "*** FIXING UP LOUDMOUTH"
	ed -s loudmouth-1.4.3/loudmouth/lm-error.c \
	    < edscripts/loudmouth.lm-error.ed
	[[ -f loudmouth-1.4.3/configure ]] && \
	    touch loudmouth-1.4.3/configure

0-loudmouth-stamp: 0-package-stamp loudmouth-1.4.3/config.status
	@echo "*** BUILDING LOUDMOUTH"
	cd loudmouth-1.4.3 && \
		make install DESTDIR=$(PROTO)
	touch $@
	@echo "*** DONE WITH LOUDMOUTH"

##### IRSSI-XMPP

irssi-xmpp-$(XMPP_VERSION)/Makefile: downloads/irssi-xmpp-$(XMPP_VERSION).tar.gz
	@echo "*** EXTRACTING IRSSI-XMPP"
	tar xvfz downloads/irssi-xmpp-$(XMPP_VERSION).tar.gz
	@echo "*** FIXING UP IRSSI-XMPP"
	ed -s irssi-xmpp-$(XMPP_VERSION)/src/core/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-$(XMPP_VERSION)/src/fe-common/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-$(XMPP_VERSION)/src/fe-text/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-$(XMPP_VERSION)/config.mk \
		< edscripts/irssi-xmpp.config.ed
	[[ -f irssi-xmpp-$(XMPP_VERSION)/Makefile ]] && \
		touch irssi-xmpp-$(XMPP_VERSION)/Makefile

0-irssi-xmpp-stamp: 0-package-stamp irssi-xmpp-$(XMPP_VERSION)/Makefile 0-loudmouth-stamp
	@echo "*** BUILDING IRSSI-XMPP"
	cd irssi-xmpp-$(XMPP_VERSION) && \
		export PKG_CONFIG_PATH=$(PROTO)/$(PREFIX)/lib/pkgconfig && \
		export PREFIX=$(PREFIX) && \
		export PROTO=$(PROTO) && \
		export IRSSI_INCLUDE=$(PROTO)/$(PREFIX)/include/irssi && \
		make install DESTDIR=$(PROTO)
	touch "$@"
	@echo "*** DONE WITH IRSSI-XMPP"

##### OTHER TARGETS

.PHONY: clean
clean:
	rm -rf loudmouth-1.4.3
	rm -rf irssi-xmpp-$(XMPP_VERSION)
	rm -rf irssi-$(IRSSI_VERSION)
	rm -f 0-irssi-stamp 0-irssi-xmpp-stamp 0-loudmouth-stamp

.PHONY: clobber
clobber: clean
	rm -rf proto

.PHONY: nuke
nuke: clobber
	rm -rf downloads

