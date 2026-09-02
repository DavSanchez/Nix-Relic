{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "newrelic-fluent-bit-output";
  version = "3.8.0";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "newrelic-fluent-bit-output";
    rev = "v${version}";
    hash = "sha256-Hevplsdhj3c/ZPg+bO5IMgzjMBBmwGh5XWAcT/ndSXo=";
  };

  # The plugin is built as a C shared object loaded by Fluent Bit
  env.CGO_ENABLED = 1;

  vendorHash = "sha256-HwPCEg47b5UkWChjGw3WanPEvt2Igvsj23Ceft9y6/Y=";

  buildPhase = ''
    runHook preBuild
    go build -buildvcs=false -buildmode=c-shared -o ${pname}.so .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp ${pname}.so $out/lib/out_newrelic.so
    runHook postInstall
  '';

  meta = {
    description = "A Fluent Bit output plugin that sends logs to New Relic";
    homepage = "https://github.com/newrelic/newrelic-fluent-bit-output";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ davsanchez ];
    platforms = lib.platforms.linux;
  };
}
