{
  description = "data-ops-challenge";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in {

    packages.default = pkgs.stdenvNoCC.mkDerivation {
      name = "data-ops-challenge";

      nativeBuildInputs = (with pkgs; [
        xsv
        jq
        coreutils  # This provides 'chmod'
      ]);

      src = ./.;

      buildPhase = ''
      mkdir -p $out
      cd $src

      # Ensure transform.bash is executable
      chmod +x ./transform.bash


      BUILD_DIR=$out ./transform.bash
      '';

      doCheck = true;
      checkPhase = ''
        diff -q $src/tests/output.csv $out/user-policies.csv
      '';
    };
  });
}

#I have set the permissions to execute outside of flake.nix, but it appears to fail on the github test