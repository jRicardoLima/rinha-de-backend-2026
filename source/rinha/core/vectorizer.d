module rinha.core.vectorizer;

import rinha.core.types;
import rinha.utils.helpers;
import std.algorithm : clamp, canFind;
import std.datetime;
import std.conv : to;
import std.stdio : writeln;

class Vectorizer
{
    public float[14] buildFeatureVector(
        scope TransactionInput tx,
        immutable Normalization normalize,
        double[string] mccRisk
    ) @trusted
    {

        float[14] vector;

        double amountNorm = clamp(tx.amount / normalize.maxAmount,0.0,1.0);

        vector[0] = cast(float) amountNorm;

        double instNorm = clamp(tx.installments / cast(double)normalize.maxInstallments,0.0,1.0);

        vector[1] = cast(float) instNorm;

        double ratio = tx.avgAmount > 0 ? tx.amount / tx.avgAmount : 0;
        double ratioNorm = clamp(ratio / normalize.amountVsAvgRatio,0.0,1.0);

        vector[2] = cast(float) ratioNorm;

        vector[3] = tx.requestedAt.convertToTimestamp.convertTimestampToHours / 23;

        vector[4] = tx.requestedAt.convertToTimestamp.convertTimestampToDayOfWeek / 6;

        if(tx.lastTransactionTimestamp.isNull) {
            vector[5] = -1f;
        } else {
            auto requestedTs = tx.requestedAt.convertToTimestamp;
            auto lastTs = tx.lastTransactionTimestamp.get.convertToTimestamp;

            auto deltaMinutes = (requestedTs - lastTs) / 60.0;

            vector[5] = cast(float) clamp(deltaMinutes / normalize.maxMinutes, 0.0, 1.0);
        }
        vector[5] = tx.lastTransactionTimestamp.isNull ? -1 :  tx.requestedAt.convertToTimestamp
                                                                 .convertTimestampToMinutes / normalize.maxMinutes;

        if(tx.lastTransactionKmFromCurrent.isNull) {
            vector[6] = -1;
        } else {
            auto kmFromLast = tx.lastTransactionKmFromCurrent.get.to!float;
            vector[6] = cast(float) clamp(kmFromLast / normalize.maxKm ,0.0,1.0);
        }

        vector[7] = cast(float) clamp(tx.terminalKmFromHome / normalize.maxKm,0.0,1.0);

        vector[8] = cast(float) clamp(tx.txCount24 / cast(double) normalize.maxTxCount24,0.0,1.0);

        vector[9] = tx.terminalIsOnline ? 1 : 0;

        vector[10] = tx.terminalCardPresent ? 1 : 0;

        vector[11] = tx.knownMerchants.canFind(tx.merchantId) ? 0 : 1;

        vector[12] = tx.merchantMCC in mccRisk ? mccRisk[tx.merchantMCC] : 0.5;

        vector[13] = cast(float) clamp(tx.merchantAvgAmount / normalize.maxMerchantAvgAmount,0.0,1.0);

        return vector;

    }
}