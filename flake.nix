{
  description = "ILIAS to Booklet conversion script";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = import nixpkgs { inherit system; };
        script-name = "ilias-to-booklet";
        script-version = "0.1-git-20240925";
        commands-used-in-script = with pkgs; [ 
            p7zip findutils imagemagick gnused bc pdftk ghostscript
            poppler_utils # for pdfinfo
            coreutils # for mv, cp, tee
						file
          ];
        #ilias-to-booklet = (pkgs.writeScriptBin my-name (builtins.readFile ./ilias-to-booklet.sh)).overrideAttrs (old: {
        #  buildCommand = "${old.buildCommand}\n patchShebangs $out";
        #});
      in rec {
        defaultPackage = packages.ilias-to-booklet-converter;
        packages.ilias-to-booklet-converter = pkgs.stdenv.mkDerivation {
          src = ./.;
          pname = script-name; # don't forget to include version number eventually
          version = script-version;
          inherit system;
          nativeBuildInputs = [ pkgs.makeWrapper ]; # We don't need this at run time, so it's nativeBuildInputs rather than buildInputs.
          unpackPhase = ''
          cp ${./ilias-to-booklet.sh} ilias-to-booklet.sh
          '';
          buildPhase = ''
          patchShebangs ilias-to-booklet.sh
          '';
          installPhase = ''
          mkdir -p $out/bin
          mv ilias-to-booklet.sh $out/bin/ilias-to-booklet
          
          wrapProgram $out/bin/ilias-to-booklet --set PATH ${nixpkgs.lib.makeBinPath commands-used-in-script}
          #wrapProgram $out/bin/ilias-to-booklet --prefix PATH : ${nixpkgs.lib.makeBinPath commands-used-in-script}

	  '';
	}; 

      }
    );
    #);
}
