{ mitm-cache
, lib
}:

{ data, pname ? throw "Please pass pname to fetchDeps", name ? "${pname}-deps", ... } @ attrs:

let
  data' = builtins.removeAttrs
  (if builtins.isPath data then builtins.fromJSON (builtins.readFile data) else data)
  [ "!comment" ];
  visitAttrs = parent1: prefix: attrs: builtins.foldl' (a: b: a // b) {} (lib.mapAttrsToList (visit parent1 attrs prefix) attrs);
  decompressNameVer = prefix: let
    splitHash = lib.splitString "#" (builtins.concatStringsSep "/" prefix);
    nameVer = builtins.match "(.*/)?(.*)/(.*)" (lib.last splitHash);
    init = toString (builtins.head nameVer);
    name = builtins.elemAt nameVer 1;
    ver = builtins.elemAt nameVer 2;
  in
    if builtins.length splitHash == 1 then builtins.head splitHash
    else builtins.concatStringsSep "/${name}/${ver}/" (lib.init splitHash ++ [ "${init}${name}-${ver}" ]);
  visit = parent2: parent1: prefix: k: v:
    if builtins.isAttrs v && !v?groupId
    then visitAttrs parent1 (prefix ++ [k]) v
    else let
      prefix' = decompressNameVer prefix;
    in {
      "${prefix'}.${k}" =
        (if builtins.isString v then { sha256 = v; }
        # we could record the maven metadata XML in the lockfiles
        # however, that decreases security by giving the lockfiles
        # more opportunity to modify Gradle's behavior, and we don't
        # want that
        else v);
    };
    preppedData = visitAttrs {} [] data';
    finalData = preppedData // lib.genAttrs (builtins.filter (lib.hasSuffix ".xml") (builtins.attrNames preppedData)) (url: {
      text = let
        snapshotBase = lib.removeSuffix "/maven-metadata.xml" url;
        fileList = builtins.filter (lib.hasPrefix snapshotBase) (builtins.attrNames preppedData);
        jarPomUrlList = builtins.filter (x: lib.hasSuffix ".jar" x || lib.hasSuffix ".pom" x) fileList;
        inherit (preppedData.${url}) groupId;
        splitBase = lib.splitString "/" snapshotBase;
        jarPomList = map (x: let
          extension = lib.last (lib.splitString "." x);
          subPath = lib.removePrefix "${snapshotBase}/" (lib.removeSuffix ".${extension}" x);
          version =
            if isSnapshot then lib.removePrefix "${artifactId}-" (builtins.head (lib.splitString "/" subPath))
            else builtins.head (lib.splitString "/" subPath);
        in {
          inherit extension version;
          timestamp = builtins.elemAt (lib.splitString "-" version) 1;
        }) jarPomUrlList;
        sortedJarPomList =
          lib.sort
            (a: b: lib.splitVersion a.version < lib.splitVersion b.version)
            jarPomList;
        uniqueVersions' =
          (builtins.map ({ i, x }: x.version)
            (builtins.filter ({ i, x }: i == 0 || (builtins.elemAt sortedJarPomList (i - 1)).version != x.version)
              (lib.imap0 (i: x: { inherit i x; }) sortedJarPomList)));
        latestVer = preppedData.${url}.latest or (lib.last uniqueVersions');
        uniqueVersions =
          if builtins.elem latestVer uniqueVersions' then uniqueVersions'
          else uniqueVersions' ++ [ latestVer ];
        isSnapshot = lib.hasInfix "-SNAPSHOT" url;
        artifactId = builtins.elemAt splitBase (builtins.length splitBase - (if isSnapshot then 2 else 1));
        snapshotVer = lib.last splitBase;
        snapshotTsAndNum = lib.splitString "-" latestVer;
        snapshotTs = builtins.elemAt snapshotTsAndNum 1;
        snapshotNum = lib.last snapshotTsAndNum;
        indent = x: s: builtins.concatStringsSep "\n" (map (s: x + s) (lib.splitString "\n" s));
        in
          assert lib.hasInfix "${builtins.replaceStrings ["."] ["/"] groupId}/${artifactId}" url;
        if isSnapshot then ''
        <?xml version="1.0" encoding="UTF-8"?>
        <metadata modelVersion="1.1.0">
          <groupId>${groupId}</groupId>
          <artifactId>${artifactId}</artifactId>
          <version>${snapshotVer}</version>
          <versioning>
            <snapshot>
              <timestamp>${snapshotTs}</timestamp>
              <buildNumber>${snapshotNum}</buildNumber>
            </snapshot>
            <lastUpdated>${builtins.replaceStrings ["."] [""] snapshotTs}</lastUpdated>
            <snapshotVersions>
        ${builtins.concatStringsSep "\n" (map (x: indent "      " ''
              <snapshotVersion>
                <extension>${x.extension}</extension>
                <value>${x.version}</value>
                <updated>${builtins.replaceStrings ["."] [""] x.timestamp}</updated>
              </snapshotVersion>'') sortedJarPomList)}
            </snapshotVersions>
          </versioning>
        </metadata>
      '' else ''
        <?xml version="1.0" encoding="UTF-8"?>
        <metadata modelVersion="1.1.0">
          <groupId>${groupId}</groupId>
          <artifactId>${artifactId}</artifactId>
          <versioning>
            <latest>${latestVer}</latest>
            <release>${latestVer}</release>
            <versions>
        ${builtins.concatStringsSep "\n" (map (x: "      <version>${x}</version>") uniqueVersions)}
            </versions>
            <lastUpdated>20240101123456</lastUpdated>
          </versioning>
        </metadata>
      '';
    });
in
  mitm-cache.fetch (builtins.removeAttrs attrs [ "pname" ] // {
    inherit name;
    data = finalData;
  })
