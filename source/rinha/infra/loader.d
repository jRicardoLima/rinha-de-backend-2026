module rinha.infra.loader;

import rinha.core.types;
import std.file : exists, readText;
import std.stdio : File;
import std.json : parseJSON, JSONValue, JSONType;
import std.conv : to;
import std.exception : enforce;
import std.algorithm : each, filter;
import std.stdio : writeln;
import asdf;

align(1) struct JsonResult
{
  align(1):
    string label;
    float[] vector;
}

final class LoaderDataset
{
    public double[string] loadMccRisk(string path)
    {
        if (!exists(path)) {
            throw new Exception("Mcc Risk file not found: " ~ path);
        }

        auto content = readText(path);
        JSONValue contentLines = parseJSON(content);

        double[string] mccRisk;
        foreach (key, value; contentLines.object)
        {
            double risk = asDouble(value);
            mccRisk[key] = risk;
        }

        return mccRisk;
    }
    

    public void loadReferencesBin(string binPath, string referencesPath, float threshold = 0.8f)
    {
        auto file = File(referencesPath,"r");

        auto binReferences = File(binPath,"wb");

        scope(exit) {
            file.close();
            binReferences.close();
        }
        HeaderReferences header;
        header.magicNumber = BIN_MAGIC_IVF;
        header.version_ = BIN_VERSION_IVF;
        header.totalRecords = 0;
        header.reservedSpace[] = 0;

        auto headerBytes = (cast(ubyte*) &header)[0 .. HeaderReferences.sizeof];
        binReferences.rawWrite(headerBytes);

        ulong count = 0;
        
        foreach(recordAsdf; file.byChunk(32 * 1024).parseJson.byElement) {
            ReferenceVector item;

            auto itemJson = recordAsdf.deserialize!JsonResult;

            item.label = this.parseLabel(itemJson.label);

           foreach(i, vec; itemJson.vector) {
                if(i < item.vector.length) {
                    item.vector[i] = vec;
                }
           }

          auto bytes = (cast(ubyte*) &item)[0 .. ReferenceVector.sizeof];
          binReferences.rawWrite(bytes);
          count++;
        }

        header.totalRecords = count;
        binReferences.seek(0);

        headerBytes = (cast(ubyte*) &header)[0 .. HeaderReferences.sizeof];
        binReferences.rawWrite(headerBytes);
        binReferences.flush();
    }

    private pure ubyte parseLabel(string value) @safe
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

    private double asDouble(JSONValue value)
    {
        switch (value.type) {
            case JSONType.integer:
                return value.integer.to!double;
            case JSONType.uinteger:
                return value.uinteger.to!double;
            case JSONType.float_:
                return value.floating;
                default:
                throw new Exception("Expected numeric JSON value");
        }
    }
}