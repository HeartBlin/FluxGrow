{
  outputs = _: { mkFlake = import ./lib/mkFlake.nix; };
}
