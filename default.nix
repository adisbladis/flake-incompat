let
  inherit (builtins)
    concatMap
    listToAttrs
    isFunction
    intersectAttrs
    functionArgs
    isPath
    attrNames
    mapAttrs
    foldl'
    ;

  callSetWith =
    autoArgs: fn:
    let
      f = if isFunction fn then fn else import fn;
    in
    f (intersectAttrs (functionArgs f) autoArgs);

  isDerivation = value: value.type or null == "derivation";

  filterDerivations =
    set:
    listToAttrs (
      concatMap (
        name:
        let
          value = set.${name};
        in
        if isDerivation value then
          [
            {
              inherit name value;
            }
          ]
        else
          [ ]
      ) (attrNames set)
    );

  defaultSystemFields = [
    "packages"
    "devShells"
    "checks"
    "formatter"
    "legacyPackages"
  ];

  defaultAttrProcessors =
    let
      filterDrvsPerSystem = mapAttrs (_: filterDerivations);
    in
    {
      packages = filterDrvsPerSystem;
      devShells = filterDrvsPerSystem;
      checks = filterDrvsPerSystem;
    };

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
          inherit self;
        }
      );

      self =
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
                  value = callSet imported.${name};
                }
              ]
          ) systemFields
        );
    in
    self;

  mkFlake =
    {
      expr,
      inputs,
      argsFun ? system: {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      },
      systems ? inputs.nixpkgs.lib.systems.flakeExposed,
      systemFields ? defaultSystemFields,
      attrProcessors ? defaultAttrProcessors,
    }:
    let
      imported = callSetWith inputs (importExpr expr);

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
    foldl' (prev: fn: fn prev) imported [
      # Get each attribute from each system
      (
        prev:
        prev
        // listToAttrs (
          concatMap (
            name:
            if !imported ? ${name} then
              [ ]
            else
              [
                ({
                  inherit name;
                  value = listToAttrs (
                    map (system: {
                      name = system;
                      value = selfs.${system}.${name};
                    }) systems
                  );
                })
              ]
          ) systemFields
        )
      )
      # Post-process any attributes as required
      (
        prev:
        prev
        // listToAttrs (
          concatMap (
            name:
            if !prev ? ${name} then
              [ ]
            else
              [
                {
                  inherit name;
                  value = attrProcessors.${name} prev.${name};
                }
              ]
          ) (attrNames attrProcessors)
        )
      )
    ];
in
{
  inherit mkFlake call;
  systemFields = defaultSystemFields;
  attrProcessors = defaultAttrProcessors;
}
