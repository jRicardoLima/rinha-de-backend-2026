module rinha.core.reference_store_ivf;

import rinha.core.types;
import rinha.core.contracts.base_bin_reference;
import std.mmfile : MmFile;
import std.file : exists, getSize;
import std.exception;
import std.conv : to;
import std.stdio : writeln;

class ReferenceStoreIFV : BaseBinReference
{
    private string pathBin;
    private MmFile mmFile;
    private const(ubyte)[] mappedData;

    private HeaderReferences header;
    private const(float)[][] centroids;
    private const(ClusterIndex)[] clusters;

    this(string pathBin)
    {
        this.pathBin = pathBin;
    }

    public void openBin()
    {
        enforce(exists(this.pathBin), "Bin file not found: " ~ this.pathBin);

        auto fileSize = getSize(this.pathBin);
        enforce(fileSize >= HeaderReferences.sizeof,
        "Bin file too small: " ~ this.pathBin);

        this.mmFile = new MmFile(this.pathBin);
        this.mappedData = cast(const(ubyte)[]) this.mmFile[];

        this.header = *cast(const(HeaderReferences)*) this.mappedData.ptr;

        enforce(this.header.magicNumber == BIN_MAGIC_IVF,
        "Invalid IVF bin magic");

        enforce(this.header.version_ == BIN_VERSION_IVF,
        "Unsupported IVF bin version");

        enforce(this.header.dimensions == VECTOR_DIMENSIONS,
        "Invalid vector dimensions");

        enforce(this.header.totalClusters > 0,
        "IVF bin has zero clusters");

        enforce(this.header.totalRecords > 0,
        "IVF bin has zero records");

        enforce(this.header.centroidsOffset < fileSize,
        "Invalid centroidsOffset");

        enforce(this.header.clusterIndexOffset < fileSize,
        "Invalid clusterIndexOffset");

        enforce(this.header.dataOffset <= fileSize,
        "Invalid dataOffset");

        auto centroidsPtr = this.mappedData.ptr + this.header.centroidsOffset;
        auto centroidFlat = (cast(const(float)*) centroidsPtr)
            [0 .. this.header.totalClusters * this.header.dimensions];

        this.centroids.length = this.header.totalClusters;

        foreach (i; 0 .. this.header.totalClusters) {
            auto start = i * this.header.dimensions;
            auto ending = start + this.header.dimensions;
            this.centroids[i] = centroidFlat[start .. ending];
        }

        auto clusterIndexPtr = this.mappedData.ptr + this.header.clusterIndexOffset;
        this.clusters = (cast(const(ClusterIndex)*) clusterIndexPtr)
            [0 .. this.header.totalClusters];

        foreach (i, cluster; this.clusters) {
            enforce(cluster.offset >= this.header.dataOffset,
            "Cluster offset before data section. cluster=" ~ i.to!string);

            enforce(cluster.offset <= fileSize,
            "Cluster offset after file end. cluster=" ~ i.to!string);

            auto clusterBytes = cluster.count * ReferenceVector.sizeof;

            enforce(cluster.offset + clusterBytes <= fileSize,
            "Cluster block exceeds file size. cluster=" ~ i.to!string);
        }

        writeln("ivf refs loaded. totalRecords=", this.header.totalRecords,
        " totalClusters=", this.header.totalClusters);
    }

    public pure const(float)[][] getCentroids() @safe
    {
        return this.centroids;
    }

    public pure const(ClusterIndex)[] getClusterIndex() @safe
    {
        return this.clusters;
    }

    public pure const(ReferenceVector)[] getClusterReferences(size_t clusterId) @trusted
    {
        enforce(clusterId < this.clusters.length, "Invalid clusterId");

        auto cluster = this.clusters[clusterId];
        auto ptr = this.mappedData.ptr + cluster.offset;

        return (cast(const(ReferenceVector)*) ptr)[0 .. cluster.count];
    }

    public pure HeaderReferences getHeader() @safe
    {
        return this.header;
    }
}