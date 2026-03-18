# Flake-incompat - The non flake-brained Flake framework

All existing Nix Flake frameworks are flake-brained & forces you to think about Flakes as a composition primitive.
This breaks cross-compilation & other advanced use cases, makes `system` a closed set & leaving users of stable Nix as second-class citizens.

Flake-incompat flips this thinking around and centers composition around a simple dependency injection pattern that works well both with stable Nix & with Flakes.
It accomplishes this by taking the good parts of Flakes, the [output schema](https://nixos.wiki/wiki/Flakes#Output_schema), and improves upon it by decoupling input handling & eliminating `system` boilerplate.

## Features
- Structure your Nix code in a way that makes sense both for classic Nix & Flakes
- Eliminates `system` boilerplate
