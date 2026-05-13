module preprocess_references;

import std.stdio;
//import rinha.infra.loader;
import rinha.infra.loader_ivf;
import std.path : dirName, buildNormalizedPath;
void main()
{

    auto path = __FILE__;
    auto currentDir = dirName(path);

    auto pathReferences = buildNormalizedPath(currentDir, "../resources/references.json.gz");
    auto pathBinReferences = buildNormalizedPath(currentDir, "../resources/references.bin");

    writeln("references: ", pathReferences);
    writeln("bin: ", pathBinReferences);

    auto loader = new LoaderDatasetIvf();
    loader.loadReferencesIvfBin(pathBinReferences, pathReferences, 64, 2);

}