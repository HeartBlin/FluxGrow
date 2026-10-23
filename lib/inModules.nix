root:

let
  findModules = dir: let
    entries = builtins.readDir dir;
    process = name: type: let
      path = dir + "/${name}";
    in
      if builtins.substring 0 1 name == "_"
      then [ ]
      else if type == "directory"
      then findModules path
      else if builtins.match ".*\\.nix" name != null
      then [ path ]
      else [ ];
  in
    builtins.concatLists (
      map (name: process name entries.${name}) (builtins.attrNames entries)
    );

  paths = findModules root;
in
  builtins.foldl' (
    acc: path: let
      modName = builtins.head (builtins.match "(.*)\\.nix" (baseNameOf path));
    in
      if builtins.hasAttr modName acc
      then throw "inModules: duplicate module name '${modName}':\n  ${toString acc.${modName}}\n  ${toString path}"
      else acc // { ${modName} = path; }
  ) { }
  paths
