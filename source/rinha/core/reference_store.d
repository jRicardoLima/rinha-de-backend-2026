module rinha.core.reference_store;

import rinha.core.types;
import std.mmfile : MmFile;
import std.file : exists, getSize;
import std.exception;
import std.conv : to;

final class ReferenceStore
{
    private string pathBin;
    private MmFile mmFile;
    private const(ReferenceVector)[] refs;

    this(string pathBin)
    {
        this.pathBin = pathBin;
    }

    public void openBin()
    {
        if(!exists(this.pathBin)) {
            throw new Exception("Bin file not found");
        }

        auto fileSize = getSize(this.pathBin);

        enforce(fileSize >= HeaderReferences.sizeof, "Bin file to small" ~ this.pathBin);

        this.mmFile = new MmFile(this.pathBin);

        auto data = cast(const(ubyte)[]) mmFile[];

        auto header = *cast(const(HeaderReferences)*) data.ptr;

        enforce(header.magicNumber == "RNH1REFG", "Invalid bin magic");
        enforce(header.version_ == 1, "Unsupported bin version");

        enforce(header.totalRecords > 0, "Bin header has zero records");

        auto payloadBytes = fileSize - HeaderReferences.sizeof;
        auto expectedBytes = header.totalRecords * ReferenceVector.sizeof;

        enforce(payloadBytes >= expectedBytes, "Bin payload is smaller than expected. expected= "~ expectedBytes.to!string ~ " got= "~ payloadBytes.to!string);

        auto payloadPtr = data.ptr + HeaderReferences.sizeof;

        this.refs = (cast(const(ReferenceVector) *) payloadPtr)[0 .. header.totalRecords];
    }

    public const(ReferenceVector)[] getReferences() const @safe
    {
        return this.refs;
    }
}