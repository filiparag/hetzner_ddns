{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, fetchFromGitHub ? pkgs.fetchFromGitHub
, lib ? pkgs.lib
, busybox ? pkgs.busybox
, jq ? pkgs.jq
, curl ? pkgs.curl
}:

stdenv.mkDerivation rec {
	pname = "hetzner_ddns";
	version = "1.0.1";

	src = ../../.;
	
	dontBuild = true;
	dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    echo "#!${pkgs.busybox}/bin/sh" >> $out/bin/hetzner_ddns
    echo "export PATH=${pkgs.lib.makeBinPath [ busybox jq curl ]}" >> $out/bin/hetzner_ddns
    cat $src/hetzner_ddns.sh >> $out/bin/hetzner_ddns
    chmod +x $out/bin/hetzner_ddns
  '';
  

  meta = with lib; {
    description = "DynDNS Client for Hetzner DNS";
    longDescription = ''
      
    '';
    homepage = "https://github.com/filiparag/hetzner_ddns";
    license = licenses.gpl2Only;
    #maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "hetzner_ddns";
  };
}
