{
  description = "ILIAS to Booklet conversion script";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = import nixpkgs { inherit system; };
        my-name = "ilias-to-booklet";
        my-buildInputs = with pkgs; [ 
            p7zip findutils imagemagick gnused bc pdftk ghostscript
            poppler_utils # for pdfinfo
            # glibcLocales # to prevent ugly perl messages - probably no longer needed as we no longer use rename
            coreutils # for mv
          ];
        ilias-to-booklet = (pkgs.writeScriptBin my-name (builtins.readFile ./ilias-to-booklet.sh)).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        defaultPackage = packages.ilias-to-booklet-converter;
        packages.ilias-to-booklet-converter = pkgs.symlinkJoin {
          name = my-name;
          paths = [ ilias-to-booklet ] ++ my-buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
        };
      }
    );
}
