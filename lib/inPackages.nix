root: pkgs:

let
  entries = builtins.readDir root;
  validDirs = builtins.filter (
    name: entries.${name} == "directory"
  ) (builtins.attrNames entries);
in
  builtins.listToAttrs (map (name: {
      inherit name;
      value = pkgs.callPackage (root + "/${name}") { };
    })
    validDirs)
