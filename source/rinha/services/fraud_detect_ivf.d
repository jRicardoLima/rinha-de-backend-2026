module rinha.services.fraud_detect_ivf;

import rinha.core.types;
import rinha.services.distance;
import rinha.core.vectorizer;
import rinha.core.contracts.base_bin_reference;
import std.exception : enforce;

final class FraudDetectIvfService
{
    private DistanceService distanceService;
    private Vectorizer vectorizer;

    this(DistanceService distance, Vectorizer vect)
    {
        this.distanceService = distance;
        this.vectorizer = vect;
    }

    private size_t findWorstIndex(scope const(NeighborMatch)[] items) @safe pure nothrow
    {
        size_t worstIndex = 0;
        float worstDistance = items[0].distance;

        foreach (i; 1 .. items.length) {
            if (items[i].distance > worstDistance) {
                worstDistance = items[i].distance;
                worstIndex = i;
            }
        }

        return worstIndex;
    }

    private pure NeighborMatch[] findNearest(
       scope const(float)[14] queryVector,
       scope const(ReferenceVector)[] references,
        size_t k
    ) @safe
    {
        NeighborMatch[] best;
        best.reserve(k);

        size_t worstIndex = 0;
        float worstDistance = 0.0f;

        foreach (index, refItem; references) {
            auto distance = this.distanceService.euclideanDistanceSquared(queryVector, refItem.vector);
            auto candidate = NeighborMatch(index, refItem.label, distance);

            if (best.length < k) {
                best ~= candidate;

                if (best.length == k) {
                    worstIndex = this.findWorstIndex(best);
                    worstDistance = best[worstIndex].distance;
                }

                continue;
            }

            if (distance >= worstDistance) {
                continue;
            }

            best[worstIndex] = candidate;
            worstIndex = this.findWorstIndex(best);
            worstDistance = best[worstIndex].distance;
        }

        return best;
    }

    private pure NeighborMatch[] findNearestCentroids(
        scope const(float)[14] queryVector,
        scope const(float)[][] centroids,
        size_t nprobe
    ) @safe
    {
        enforce(centroids.length > 0, "No centroids loaded");

        auto probes = nprobe;
        if (probes == 0) probes = 1;
        if (probes > centroids.length) probes = centroids.length;

        NeighborMatch[] best;
        best.reserve(probes);

        size_t worstIndex = 0;
        float worstDistance = 0.0f;

        foreach (index, centroid; centroids) {
            enforce(centroid.length == 14, "Invalid centroid dimensions");

            auto distance = this.distanceService.euclideanDistanceSquared(queryVector[], centroid);
            auto candidate = NeighborMatch(index, 0, distance);

            if (best.length < probes) {
                best ~= candidate;

                if (best.length == probes) {
                    worstIndex = this.findWorstIndex(best);
                    worstDistance = best[worstIndex].distance;
                }

                continue;
            }

            if (distance >= worstDistance) {
                continue;
            }

            best[worstIndex] = candidate;
            worstIndex = this.findWorstIndex(best);
            worstDistance = best[worstIndex].distance;
        }

        return best;
    }

    private pure NeighborMatch[] findNearestInClusters(
        scope const(float)[14] queryVector,
        scope BaseBinReference store,
        scope NeighborMatch[] nearestCentroids,
        size_t k
    ) @safe
    {
        NeighborMatch[] best;
        best.reserve(k);

        size_t worstIndex = 0;
        float worstDistance = 0.0f;

        foreach (centroidMatch; nearestCentroids) {
            auto references = store.getClusterReferences(centroidMatch.index);

            foreach (index, refItem; references) {
                auto distance = this.distanceService.euclideanDistanceSquared(queryVector, refItem.vector);
                auto candidate = NeighborMatch(index, refItem.label, distance);

                if (best.length < k) {
                    best ~= candidate;

                    if (best.length == k) {
                        worstIndex = this.findWorstIndex(best);
                        worstDistance = best[worstIndex].distance;
                    }

                    continue;
                }

                if (distance >= worstDistance) {
                    continue;
                }

                best[worstIndex] = candidate;
                worstIndex = this.findWorstIndex(best);
                worstDistance = best[worstIndex].distance;
            }
        }

        return best;
    }

    public FraudDetectionResult detect(
        scope TransactionInput tx,
        immutable Normalization normalize,
        double[string] mccRisk,
        scope BaseBinReference store,
        size_t k = 5,
        size_t nprobe = 16
    ) @safe
    {
        auto queryVector = this.vectorizer.buildFeatureVector(tx, normalize, mccRisk);

        auto centroids = store.getCentroids();
        auto nearestCentroids = this.findNearestCentroids(queryVector, centroids, nprobe);
        auto neighbors = this.findNearestInClusters(queryVector, store, nearestCentroids, k);

        size_t fraudCount = 0;

        bool suspiciousByRule = false;

        if(tx.terminalKmFromHome > 150 && tx.amount > tx.avgAmount * 3.0) {
            suspiciousByRule = true;
        }

        if(!tx.terminalCardPresent && tx.amount > tx.avgAmount * 4.0) {
            suspiciousByRule = true;
        }

        if(tx.txCount24 >= 12 && tx.amount > tx.avgAmount * 2.5) {
            suspiciousByRule = true;
        }

        double fraudWeight = 0.0;
        double legitWeight = 0.0;
        double epsilon = 1e-9;

        foreach (neighbor; neighbors) {

            double weight = 1.0 / (cast(double) neighbor.distance + epsilon);

            if(neighbor.label == LABEL_FRAUD) {
                fraudWeight += weight;
            } else {
                legitWeight += weight;
            }

            //fraudCount += (neighbor.label == LABEL_FRAUD) ? 1 : 0;
        }

        double totalWeight = fraudWeight + legitWeight;

        double fraudScore = totalWeight > 0
        ? fraudWeight / totalWeight
        : 0.5;

        bool approved = fraudScore < 0.55 && !suspiciousByRule;

        return FraudDetectionResult(
            approved,
            fraudScore
        );
    }
}