import rinha.infra.server;
import rinha.infra.data_env;
import rinha.infra.loader;
import rinha.http.router;
import rinha.services.distance;
import rinha.services.fraud_detect;
import rinha.core.vectorizer;
import rinha.core.reference_store;
import rinha.core.reference_store_ivf;
import rinha.services.fraud_detect_ivf;
import rinha.core.types;
import std.conv : to;
import std.path : dirName, buildNormalizedPath;

void main()
{
	auto path = __FILE__;
	auto currentDir = dirName(path);
	//auto pathEnv = buildNormalizedPath(currentDir, "../.env");
    auto pathMccRisk = buildNormalizedPath(currentDir,"../resources/mcc_risk.json");
    //auto pathReferences = buildNormalizedPath(currentDir,"../resources/references.json");
    auto pathBinReferences = buildNormalizedPath(currentDir,"../resources/references.bin");

    auto envData = new DataEnv();
    auto env = envData.getEnv();
    auto loader = new LoaderDataset();

    auto mccRisk = loader.loadMccRisk(pathMccRisk);

    auto store = new ReferenceStoreIFV(pathBinReferences);

    store.openBin();

    auto distanceService = new DistanceService();
    auto vectorizer = new Vectorizer();
    auto fraudDetectService = new FraudDetectIvfService(distanceService,vectorizer);

    immutable Normalization normalize;

    auto router = buildRouter(
        fraudDetectService,
        normalize,
        mccRisk,
        store,
    );

    auto server = new ServerD(to!ushort(env.appPort), env.appAddress);

    server.run(router);

}