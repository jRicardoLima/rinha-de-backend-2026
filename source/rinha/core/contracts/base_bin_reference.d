module rinha.core.contracts.base_bin_reference;

import rinha.core.types;

interface BaseBinReference 
{
    public void openBin();
    public pure const(ReferenceVector)[] getClusterReferences(size_t clusterId) @trusted;
    public pure const(float)[][] getCentroids() @safe;
}
 
 
 
