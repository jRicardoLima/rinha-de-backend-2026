module rinha.services.fraud_detect;

import rinha.core.types;
import rinha.services.distance;
import rinha.core.vectorizer;
import rinha.core.contracts.base_bin_reference;
import std.algorithm : sort;

final class FraudDetectService
{
    private DistanceService distanceService;
    private Vectorizer vectorizer;

    this(DistanceService distance, Vectorizer vect)
    {
        this.distanceService = distance;
        this.vectorizer = vect;
    }

    //private NeighborMatch[] findNearest(
    //    const(float)[14] queryVector,
    //    const(ReferenceVector)[] references,
    //    size_t k
    //) @safe
    //{
    //    NeighborMatch[] best;
    //
    //    foreach (index, refItem; references) {
    //        auto distance = this.distanceService.euclideanDistanceSquared(queryVector, refItem.vector);
    //
    //        auto candidate = NeighborMatch(
    //            index,
    //            refItem.label,
    //            distance
    //        );
    //
    //        if(best.length < k) {
    //            best ~= candidate;
    //            best.sort!((a,b) => a.distance < b.distance);
    //            continue;
    //        }
    //
    //        if(distance < best[$ - 1].distance) {
    //            best[$ - 1] = candidate;
    //            best.sort!((a,b) => a.distance < b.distance);
    //        }
    //    }
    //    return best;
    //}

    //public FraudDetectionResult detect(
    //    TransactionInput tx,
    //    immutable Normalization normalize,
    //    double[string] mccRisk,
    //    BaseBinReference store,
    //    size_t k = 5,
    //    size_t nprobe = 4
    //) @safe
    //{
    //    auto queryVector = this.vectorizer.buildFeatureVector(tx, normalize, mccRisk);
    //
    //    auto neighbors = this.findNearest(queryVector, references, k);
    //
    //    size_t fraudCount = 0;
    //
    //    foreach (neighbor; neighbors) {
    //        if (neighbor.label == LABEL_FRAUD) {
    //            fraudCount++;
    //        }
    //    }
    //
    //    double fraudScore = neighbors.length > 0
    //    ? fraudCount / cast(double) neighbors.length
    //    : 0.0;
    //
    //    bool approved = fraudScore < 0.6;
    //
    //    return FraudDetectionResult(
    //        approved,
    //        fraudScore
    //    );
    //}
}