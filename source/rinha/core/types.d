module rinha.core.types;

import std.typecons : Nullable;

enum ubyte LABEL_LEGIT = 0;
enum ubyte LABEL_FRAUD = 1;
enum char[8] BIN_MAGIC_IVF = "RNH1IVF1";
enum ushort BIN_VERSION_IVF = 2;
enum ushort VECTOR_DIMENSIONS = 14;


align(1) struct Environment
{
  align(1):
    public string appName;
    public string appEnv;
    public string appPort;
    public string appAddress;
    public string logLevel;
}

align(1) struct TransactionInput
{
  align(1):
    string id;
    double amount;
    int installments;
    string requestedAt;
    double avgAmount;
    int txCount24;
    string[] knownMerchants;
    string merchantId;
    string merchantMCC;
    double merchantAvgAmount;
    bool terminalIsOnline;
    bool terminalCardPresent;
    double terminalKmFromHome;
    Nullable!string lastTransactionTimestamp;
    Nullable!double lastTransactionKmFromCurrent;
}

align(1) struct ReferenceVector
{
  align(1):
    float[14] vector;
    ubyte label;
}

align(1) struct NeighborMatch
{
  align(1):
    size_t index;
    ubyte label;
    float distance;
}

align(1) struct FraudDetectionResult
{
  align(1):
    bool approved;
    double fraudScore;
}

//struct HeaderReferences
//{
//    char[8] magicNumber = "RNH1REFG";
//    uint version_ = 1;
//    ulong totalRecords;
//    float threshold;
//    ubyte[16] reservedSpace;
//}

align(1) struct HeaderReferences
{
  align(1):
    char[8] magicNumber = "RNH1REFG";
    uint version_ = 1;
    ulong totalRecords;
    uint dimensions;
    uint totalClusters;
    ulong centroidsOffset;
    ulong clusterIndexOffset;
    ulong dataOffset;
    ubyte[16] reservedSpace;
}

align(1) struct ClusterIndex
{
  align(1):
    ulong offset;
    ulong count;
}

align(1) immutable struct Normalization
{
  align(1):
    uint maxAmount = 10000;
    uint maxInstallments = 12;
    uint amountVsAvgRatio = 10;
    uint maxMinutes = 1440;
    uint maxKm = 1000;
    uint maxTxCount24 = 20;
    uint maxMerchantAvgAmount = 10000;
}

