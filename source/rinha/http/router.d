module rinha.http.router;
import rinha.http.handlers.ready_handler : ReadyHandler;
import rinha.http.handlers.fraud_handler : FraudHandler;
import rinha.core.types;
import rinha.core.reference_store;
import rinha.core.contracts.base_bin_reference;
import rinha.services.fraud_detect_ivf;

import vibe.vibe;

URLRouter buildRouter(
    FraudDetectIvfService fraudDetectService,
    immutable Normalization normalization,
    double[string] mccRisk,
    BaseBinReference store
)
{
    auto router = new URLRouter();
    auto readyHandler = new ReadyHandler();
    auto fraudHandler = new FraudHandler(fraudDetectService, normalization, mccRisk, store);

    router.get("/ready",&readyHandler.ready);
    router.post("/fraud-score",&fraudHandler.score);

    return router;
}



