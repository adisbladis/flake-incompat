let
  inherit (builtins)
    concatMap
    listToAttrs
    isFunction
    intersectAttrs
    functionArgs
    isPath
    ;

  callSetWith =
    autoArgs: fn: args:
    let
      f = if isFunction fn then fn else import fn;
      auto = intersectAttrs (functionArgs f) autoArgs;
      origArgs = auto // args;
    in
    f origArgs;

  defaultSystemFields = [
    "packages"
    "devShells"
    "checks"
    "formatter"
    "legacyPackages"
  ];

  importExpr = expr: if isPath expr then import expr else expr;

  call =
    {
      expr,
      args,
      systemFields ? defaultSystemFields,
    }:
    let
      imported = importExpr expr;

      callSet = callSetWith (
        args
        // {
          inherit self';
        }
      );

      self' =
        imported
        // listToAttrs (
          concatMap (
            name:
            if !imported ? ${name} then
              [ ]
            else
              [
                {
                  inherit name;
                  value = callSet imported.${name} { };
                }
              ]
          ) systemFields
        );
    in
    self';

  mkFlake =
    {
      expr,
      inputs,
      argsFun ? system: {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      },
      systems ? inputs.nixpkgs.lib.systems.flakeExposed,
      systemFields ? defaultSystemFields,
    }:
    let
      imported = callSetWith inputs (importExpr expr) { };

      # A self fixpoint per system
      selfs = listToAttrs (
        map (system: {
          name = system;
          value = call {
            args = argsFun system;
            expr = imported;
            inherit systemFields;
          };
        }) systems
      );
    in
    imported
    // listToAttrs (
      concatMap (
        name:
        if !imported ? ${name} then
          [ ]
        else
          [
            (
              {
                inherit name;
                value = listToAttrs (
                  map (system: {
                    name = system;
                    value = selfs.${system}.${name};
                  }) systems
                );
              }
            )
          ]
      ) systemFields
    );

in
{
  inherit mkFlake call;
  systemFields = defaultSystemFields;
}
