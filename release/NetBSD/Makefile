# $NetBSD: Makefile,v 1.136 2023/08/06 14:04:00 ryoon Exp $

DISTNAME=	hetzner_ddns
PKGVER=		1.0.1
PKGNAME=	${DISTNAME}-${PKGVER}
CATEGORIES=	net

MAINTAINER=	filip@parag.rs
HOMEPAGE=	https://github.com/${GITHUB_USER}/${DISTNAME}
COMMENT=	Hetzner Dynamic DNS Daemon
LICENSE=	2-clause-bsd

GITHUB_USER=	filiparag
MASTER_SITES=	${MASTER_SITE_GITHUB:=filiparag/}
GITHUB_TAG=	${PKGVER}

INSTALLATION_DIRS=	bin ${PREFIX}/share/examples/rc.d \
			${PREFIX}/${PKGMANDIR}/man1 ${EGDIR}

WRKSRC=		${WRKDIR}/${DISTNAME}-${PKGVER}
NO_BUILD=	yes
NO_CONFIGURE=	yes

EGDIR=			${PREFIX}/share/examples/${DISTNAME}
CONF_FILES_PERMS=	${EGDIR}/${DISTNAME}.json ${PKG_SYSCONFDIR}/${DISTNAME}.json \
			root wheel 0640

RCD_SCRIPTS=	${DISTNAME}
RCD_SCRIPT_SRC.${DISTNAME}?=	${WRKSRC}/${DISTNAME}.netbsd.rc

DEPENDS+=	jq-[0-9]*:../../devel/jq
DEPENDS+=	curl-[0-9]*:../../www/curl

do-patch:
	find ${WRKSRC} -maxdepth 1 -type f \
		-exec sed -i "s:/usr/local/etc:${PKG_SYSCONFDIR}:g" {} \; \
		-exec sed -i "s:/usr/local:${PREFIX}:g" {} \;

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/${DISTNAME}.sh \
		${DESTDIR}${PREFIX}/bin/${DISTNAME}
	${INSTALL_MAN} ${WRKSRC}/${DISTNAME}.1.man \
		${DESTDIR}${PREFIX}/${PKGMANDIR}/man1/${DISTNAME}.1
	${INSTALL_DATA} ${WRKSRC}/${DISTNAME}.json \
		${DESTDIR}${EGDIR}/${DISTNAME}.json

.include "../../mk/bsd.pkg.mk"
