module rinha.services.distance;

import std.exception : enforce;

final class DistanceService
{
    public pure float euclideanDistanceSquared(scope const(float)[14] a, scope const(float)[14] b) const @safe
    {
        float sum = 0.0f;

        foreach (i; 0 .. 14)
        {
            float diff = a[i] - b[i];
            sum += diff * diff;
        }

        return sum;
    }

    public pure float euclideanDistanceSquared(scope const(float)[] a, scope const(float)[] b) const @safe
    {
        enforce(a.length == b.length, "Os vetores precisam ter o mesmo tamanho");

        float sum = 0.0f;

        foreach (i; 0 .. a.length)
        {
            float diff = a[i] - b[i];
            sum += diff * diff;
        }

        return sum;
    }
}