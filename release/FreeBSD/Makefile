PORTNAME=	hetzner_ddns
DISTVERSION=	1.0.0
PORTREVISION=	0
CATEGORIES=	dns

MAINTAINER=	filip@parag.rs
COMMENT=	Hetzner Dynamic DNS Daemon
WWW=		https://github.com/filiparag/hetzner_ddns

LICENSE=	BSD2CLAUSE

RUN_DEPENDS=	jq:textproc/jq \
		curl:ftp/curl

NO_ARCH=	yes
NO_BUILD=	yes

USE_GITHUB=	yes
GH_ACCOUNT=	filiparag

PLIST_FILES=	bin/${PORTNAME} \
		share/man/man1/${PORTNAME}.1.gz \
		"@sample etc/${PORTNAME}.json.sample"

USE_RC_SUBR=	${PORTNAME}

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/${PORTNAME}.sh \
		${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${INSTALL_MAN} ${WRKSRC}/${PORTNAME}.1.man \
		${STAGEDIR}${PREFIX}/share/man/man1/${PORTNAME}.1
	${INSTALL_DATA} ${WRKSRC}/${PORTNAME}.json ${STAGEDIR}${PREFIX}/etc/${PORTNAME}.json.sample

.include <bsd.port.mk>
