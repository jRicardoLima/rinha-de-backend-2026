module rinha.infra.server;

import vibe.d;

class ServerD
{
    private ushort port;
    private string address;

    this(ushort port, string address)
    {
        this.port = port;
        this.address = address;
    }

    public void run(HTTPServerRequestHandler router) @safe
    {
        auto server = new HTTPServerSettings;

        server.port = this.port;
        server.bindAddresses = [this.address];

        listenHTTP(server,router);

        runApplication();
    }
}

