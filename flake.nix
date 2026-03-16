{
  description = "flake-incompat";
  outputs =
    { ... }:
    {
      lib = import ./.;
    };
}
