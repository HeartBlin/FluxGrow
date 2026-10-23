{
  outputs = _: {
    lib.mkFlake = import ./lib/mkFlake.nix;
  };
}
