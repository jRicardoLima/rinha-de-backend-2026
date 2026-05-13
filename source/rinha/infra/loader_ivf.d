module rinha.infra.loader_ivf;

import rinha.core.types;
import rinha.services.distance;

import std.exception : enforce;
import std.file : exists, read;
import std.path : extension;
import std.process : execute;
import std.stdio : File;

import asdf;

align(1) struct JsonResult
{
    align(1):
    string label;
    float[] vector;
}

final class LoaderDatasetIvf
{
    private enum size_t DIMENSIONS = 14;

    private DistanceService distanceService;

    this()
    {
        this.distanceService = new DistanceService();
    }

    public void loadReferencesIvfBin(
        string binPath,
        string referencesPath,
        size_t totalClusters = 256,
        size_t iterations = 2
    )
    {
        auto references = this.loadReferenceVectors(referencesPath);

        enforce(references.length > 0, "Empty references dataset");
        enforce(totalClusters > 0, "totalClusters must be > 0");

        if (totalClusters > references.length) {
            totalClusters = references.length;
        }

        auto centroids = this.initializeCentroids(references, totalClusters);

        size_t[] assignments;
        assignments.length = references.length;

        foreach (_; 0 .. iterations) {
            this.assignToNearestCentroid(references, centroids, assignments);
            this.recomputeCentroids(references, assignments, centroids);
        }

        auto grouped = this.groupByCluster(references, assignments, totalClusters);

        this.writeIvfBin(binPath, grouped, centroids);
    }

    private ReferenceVector[] loadReferenceVectors(string referencesPath)
    {
        auto jsonContent = this.readJsonInput(referencesPath);

        ReferenceVector[] references;

        foreach (recordAsdf; jsonContent.parseJson.byElement) {
            ReferenceVector item;
            auto itemJson = recordAsdf.deserialize!JsonResult;

            item.label = this.parseLabel(itemJson.label);

            foreach (i, vec; itemJson.vector) {
                if (i < item.vector.length) {
                    item.vector[i] = vec;
                }
            }

            references ~= item;
        }

        return references;
    }

    private float[][] initializeCentroids(
        scope const(ReferenceVector)[] refs,
        size_t totalClusters
    )
    {
        float[][] centroids;
        centroids.length = totalClusters;

        auto step = refs.length / totalClusters;
        if (step == 0) {
            step = 1;
        }

        foreach (i; 0 .. totalClusters) {
            auto idx = (i * step) % refs.length;
            centroids[i] = refs[idx].vector[].dup;
        }

        return centroids;
    }

    private void assignToNearestCentroid(
        scope const(ReferenceVector)[] refs,
        float[][] centroids,
        ref size_t[] assignments
    )
    {
        foreach (i, refItem; refs) {
            size_t bestCluster = 0;
            double bestDistance = double.max;

            foreach (clusterId, centroid; centroids) {
                auto dist = this.distanceService.euclideanDistanceSquared(
                    refItem.vector[],
                    centroid
                );

                if (dist < bestDistance) {
                    bestDistance = dist;
                    bestCluster = clusterId;
                }
            }

            assignments[i] = bestCluster;
        }
    }

    private void recomputeCentroids(
        scope const(ReferenceVector)[] refs,
        scope const(size_t)[] assignments,
        ref float[][] centroids
    )
    {
        auto k = centroids.length;
        double[][] sums;
        size_t[] counts;

        sums.length = k;
        counts.length = k;

        foreach (i; 0 .. k) {
            sums[i].length = DIMENSIONS;
        }

        foreach (i, refItem; refs) {
            auto clusterId = assignments[i];
            counts[clusterId]++;

            foreach (d; 0 .. DIMENSIONS) {
                sums[clusterId][d] += refItem.vector[d];
            }
        }

        foreach (clusterId; 0 .. k) {
            if (counts[clusterId] == 0) {
                continue;
            }

            foreach (d; 0 .. DIMENSIONS) {
                centroids[clusterId][d] =
                cast(float)(sums[clusterId][d] / counts[clusterId]);
            }
        }
    }

    private pure ReferenceVector[][] groupByCluster(
        scope const(ReferenceVector)[] refs,
        scope const(size_t)[] assignments,
        size_t totalClusters
    )
    {
        ReferenceVector[][] grouped;
        grouped.length = totalClusters;

        foreach (i, refItem; refs) {
            grouped[assignments[i]] ~= refItem;
        }

        return grouped;
    }

    private void writeIvfBin(
        string outputPath,
        scope ReferenceVector[][] grouped,
        float[][] centroids
    )
    {
        auto file = File(outputPath, "wb");
        scope(exit) file.close();

        HeaderReferences header;
        header.magicNumber = BIN_MAGIC_IVF;
        header.version_ = BIN_VERSION_IVF;
        header.totalRecords = 0;
        header.dimensions = DIMENSIONS;
        header.totalClusters = cast(uint)grouped.length;
        header.reservedSpace[] = 0;

        foreach (cluster; grouped) {
            header.totalRecords += cluster.length;
        }

        header.centroidsOffset = HeaderReferences.sizeof;
        header.clusterIndexOffset =
        header.centroidsOffset + cast(ulong)(grouped.length * DIMENSIONS * float.sizeof);
        header.dataOffset =
        header.clusterIndexOffset + cast(ulong)(grouped.length * ClusterIndex.sizeof);

        this.writeStruct(file, header);

        foreach (centroid; centroids) {
            enforce(centroid.length == DIMENSIONS, "Invalid centroid length");
            file.rawWrite(centroid);
        }

        ClusterIndex[] clusterIndex;
        clusterIndex.length = grouped.length;

        ulong currentOffset = header.dataOffset;

        foreach (i, cluster; grouped) {
            clusterIndex[i].offset = currentOffset;
            clusterIndex[i].count = cast(ulong)cluster.length;
            currentOffset += cast(ulong)(cluster.length * ReferenceVector.sizeof);
        }

        foreach (ref idx; clusterIndex) {
            this.writeStruct(file, idx);
        }

        foreach (cluster; grouped) {
            if (cluster.length > 0) {
                file.rawWrite(cluster);
            }
        }

        file.flush();
    }

    private ubyte parseLabel(string value)
    {
        if (value == "fraud") {
            return LABEL_FRAUD;
        }

        if (value == "legit") {
            return LABEL_LEGIT;
        }

        throw new Exception("Unknown reference label: " ~ value);
    }

    private void writeStruct(T)(ref File file, ref T value)
    {
        auto bytes = (cast(ubyte*) &value)[0 .. T.sizeof];
        file.rawWrite(bytes);
    }

    private string readJsonInput(string path)
    {
        enforce(exists(path), "References file not found: " ~ path);

        if (extension(path) == ".gz") {
            auto result = execute(["gunzip", "-c", path]);
            enforce(
                result.status == 0,
                "Failed to decompress gzip file: " ~ path ~ " -> "
            );
            return result.output;
        }

        auto bytes = cast(ubyte[]) read(path);
        return cast(string) bytes.idup;
    }
}