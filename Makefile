
PROTO		= $(PWD)/proto
PREFIX		= /opt/irssi-xmpp

PKG_INFO	= /opt/local/sbin/pkg_info

all: 0-setup-stamp \
	downloads \
	0-irssi-stamp \
	0-loudmouth-stamp \
	0-irssi-xmpp-stamp


downloads: 0-setup-stamp \
    downloads/loudmouth-1.4.3.tar.gz \
    downloads/irssi-0.8.15.tar.gz \
    downloads/irssi-xmpp-0.52.tar.gz

downloads/loudmouth-1.4.3.tar.gz:
	curl -kL \
		http://ftp.gnome.org/pub/GNOME/sources/loudmouth/1.4/loudmouth-1.4.3.tar.gz \
		> $@

downloads/irssi-xmpp-0.52.tar.gz:
	curl -kL \
		http://cybione.org/~irssi-xmpp/files/irssi-xmpp-0.52.tar.gz \
		> $@

downloads/irssi-0.8.15.tar.gz:
	curl -kL \
		http://irssi.org/files/irssi-0.8.15.tar.gz \
		> $@

0-setup-stamp:
	mkdir downloads
	touch 0-setup-stamp

package-checks:
	@echo "*** CHECKING FOR GNUTLS"
	$(PKG_INFO) gnutls >/dev/null 2>&1 || \
		(echo "ATTN: you should ... pkgin in gnutls" >&2 && exit 1)
	@echo "*** CHECKING FOR GLIB2"
	$(PKG_INFO) glib2 >/dev/null 2>&1 || \
		(echo "ATTN: you should ... pkgin in glib2" >&2 && exit 1)

loudmouth-1.4.3/config.status: loudmouth-1.4.3/configure
	@echo "*** CONFIGURING LOUDMOUTH"
	export LIBGNUTLS_CONFIG=$$PWD/bin/libgnutls-config && \
		cd loudmouth-1.4.3 && \
		./configure --prefix=$(PREFIX)

loudmouth-1.4.3/configure: package-checks downloads/loudmouth-1.4.3.tar.gz
	@echo "*** EXTRACTING LOUDMOUTH"
	tar xvfz downloads/loudmouth-1.4.3.tar.gz
	rm -f loudmouth-1.4.3/config.status
	[[ -f loudmouth-1.4.3/configure ]] && \
		touch loudmouth-1.4.3/configure

irssi-0.8.15/configure: downloads/irssi-0.8.15.tar.gz
	@echo "*** EXTRACTING IRSSI"
	tar xvfz downloads/irssi-0.8.15.tar.gz
	rm -f irssi-0.8.15/config.status
	[[ -f irssi-0.8.15/configure ]] && \
		touch irssi-0.8.15/configure

irssi-0.8.15/config.status: package-checks irssi-0.8.15/configure
	@echo "*** CONFIGURING IRSSI"
	export LDFLAGS="-R$(PREFIX)/lib" && \
	cd irssi-0.8.15 && \
		./configure --prefix=$(PREFIX)

0-irssi-stamp: package-checks irssi-0.8.15/config.status
	@echo "*** BUILDING IRSSI"
	cd irssi-0.8.15 && \
		make install DESTDIR=$(PROTO)
	touch 0-irssi-stamp

0-loudmouth-stamp: package-checks loudmouth-1.4.3/config.status
	@echo "*** BUILDING LOUDMOUTH"
	cd loudmouth-1.4.3 && \
		make install DESTDIR=$(PROTO)
	touch 0-loudmouth-stamp
	@echo "*** DONE WITH LOUDMOUTH"


irssi-xmpp-0.52/Makefile: downloads/irssi-xmpp-0.52.tar.gz
	@echo "*** EXTRACTING IRSSI-XMPP"
	tar xvfz downloads/irssi-xmpp-0.52.tar.gz
	@echo "*** FIXING UP IRSSI-XMPP"
	ed -s irssi-xmpp-0.52/src/core/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-0.52/src/fe-common/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-0.52/src/fe-text/module.h \
		< edscripts/irssi-xmpp.decls.ed
	ed -s irssi-xmpp-0.52/config.mk \
		< edscripts/irssi-xmpp.config.ed
	[[ -f irssi-xmpp-0.52/Makefile ]] && \
		touch irssi-xmpp-0.52/Makefile

0-irssi-xmpp-stamp: package-checks irssi-xmpp-0.52/Makefile 0-loudmouth-stamp
	cd irssi-xmpp-0.52 && \
		export PREFIX=$(PREFIX) && \
		export PROTO=$(PROTO) && \
		export IRSSI_INCLUDE=$(PROTO)/$(PREFIX)/include/irssi && \
		make install DESTDIR=$(PROTO)
	touch 0-irssi-xmpp-stamp

clean:
	rm -rf loudmouth-1.4.3
	rm -rf irssi-xmpp-0.52
	rm -rf irssi-0.8.15
	rm -f 0-irssi-stamp 0-irssi-xmpp-stamp 0-loudmouth-stamp

clobber: clean
	rm -rf proto

nuke: clobber
	rm 0-setup-stamp
	rm -rf downloads


.PHONY:	package-checks
