module rinha.http.handlers.fraud_handler;

import rinha.core.types;
import rinha.services.fraud_detect_ivf;
import rinha.core.contracts.base_bin_reference;
import rinha.utils.helpers;
import vibe.vibe;
import vibe.data.json : Json, serializeToJsonString;
import vibe.core.log : logError;
import std.typecons : nullable;
import std.exception;

final class FraudHandler
{
    private FraudDetectIvfService fraudDetectService;
    private immutable Normalization normalization;
    private double[string] mccRisk;
    private BaseBinReference store;

    this(
        FraudDetectIvfService fraudDetectService,
        immutable Normalization normalization,
        double[string] mccRisk,
        BaseBinReference store,
    ) @safe
    {
        this.fraudDetectService = fraudDetectService;
        this.normalization = normalization;
        this.mccRisk = mccRisk;
        this.store = store;
    }

    void score(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        try {
            auto body = req.json;

            TransactionInput tx;

            tx.id = body["id"].get!string;

            tx.amount = jsonNumberAsDouble(body["transaction"]["amount"], "transaction.amount");
            tx.installments = body["transaction"]["installments"].get!int;
            tx.requestedAt = body["transaction"]["requested_at"].get!string;

            tx.avgAmount = jsonNumberAsDouble(body["customer"]["avg_amount"], "customer.avg_amount");
            tx.txCount24 = body["customer"]["tx_count_24h"].get!int;

            string[] knownMerchants;
            foreach (merchantJson; body["customer"]["known_merchants"]) {
                knownMerchants ~= merchantJson.get!string;
            }
            tx.knownMerchants = knownMerchants;

            tx.merchantId = body["merchant"]["id"].get!string;
            tx.merchantMCC = body["merchant"]["mcc"].get!string;
            tx.merchantAvgAmount = jsonNumberAsDouble(body["merchant"]["avg_amount"], "merchant.avg_amount");

            tx.terminalIsOnline = body["terminal"]["is_online"].get!bool;
            tx.terminalCardPresent = body["terminal"]["card_present"].get!bool;
            tx.terminalKmFromHome = jsonNumberAsDouble(body["terminal"]["km_from_home"], "terminal.km_from_home");

            auto lastTxNode = body["last_transaction"];

            if (lastTxNode.type != Json.Type.undefined &&
            lastTxNode.type != Json.Type.null_) {

                tx.lastTransactionTimestamp =
                nullable(lastTxNode["timestamp"].get!string);

                tx.lastTransactionKmFromCurrent =
                nullable(jsonNumberAsDouble(lastTxNode["km_from_current"], "last_transaction.km_from_current"));
            }

            auto result = fraudDetectService.detect(tx, normalization, mccRisk, this.store);

            Json response = Json.emptyObject;
            response["approved"] = result.approved;
            response["fraud_score"] = result.fraudScore;

            res.contentType = "application/json";
            res.statusCode = 200;
            res.writeBody(response.serializeToJsonString());
        }
        catch (Exception e) {
            logError("fraud-score failed: %s", e.msg);

            res.contentType = "application/json";
            res.statusCode = 500;

            Json err = Json.emptyObject;
            err["error"] = "internal_error";
            err["details"] = e.msg;
            res.writeBody(err.serializeToJsonString());
        }
    }

}