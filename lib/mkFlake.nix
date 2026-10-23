inputs: specArg:

let
  # Replacement for lib.recursiveUpdate
  recursiveUpdate = lhs: rhs:
    builtins.mapAttrs (
      name: _: let
        l = lhs.${name} or null;
        r = rhs.${name} or null;
      in
        if
          builtins.hasAttr name lhs
          && builtins.hasAttr name rhs
          && builtins.typeOf l == "set"
          && builtins.typeOf r == "set"
        then recursiveUpdate l r
        else if builtins.hasAttr name rhs
        then r
        else l
    ) (lhs // rhs);

  # Replacement for lib.isDerivation
  isDerivation = x: builtins.typeOf x == "set" && x.type or null == "derivation";

  # Purely for lib'
  spec =
    if builtins.typeOf specArg == "lambda"
    then
      specArg {
        lib' = {
          inModules = import ./inModules.nix;
          inPackages = import ./inPackages.nix;
        };
      }
    else specArg;

  # The usual forAllSystems really
  forAllSystems = f: builtins.listToAttrs (map
    (system: { name = system; value = f system; })
    spec.systems);

  # Instantiate nixpkgs. Add allowUnfree in too
  ctx = forAllSystems (system: {
    inherit system;
    pkgs = import inputs.nixpkgs (
      (spec.nixpkgs or { })
      // {
        inherit system;
        config = { allowUnfree = true; } // (spec.nixpkgs.config or { });
      }
    );
  });

  # All the ${system} yearners. hydraJobs is... special
  perSystemKeys = [ "packages" "devShells" "apps" "checks" "formatter" "legacyPackages" ];
  outputs = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = forAllSystems (system: spec.${name} ctx.${system});
    }) (builtins.filter (name: builtins.hasAttr name spec && builtins.typeOf spec.${name} == "lambda") perSystemKeys)
  );

  # Handle hydraJobs....
  hydraJobs =
    if builtins.hasAttr "hydraJobs" spec && builtins.typeOf spec.hydraJobs == "lambda"
    then {
      hydraJobs = builtins.foldl' recursiveUpdate { } (
        map (
          system: let
            wrapLeaves = tree:
              if builtins.typeOf tree == "set" && !(isDerivation tree)
              then builtins.mapAttrs (_: wrapLeaves) tree
              else { ${system} = tree; };
          in
            wrapLeaves (spec.hydraJobs ctx.${system})
        )
        spec.systems
      );
    }
    else { };
in
  removeAttrs spec [ "systems" "nixpkgs" ] // outputs // hydraJobs
