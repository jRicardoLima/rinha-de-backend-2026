module rinha.http.handlers.ready_handler;
import vibe.vibe;

final class ReadyHandler
{

    void ready(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        res.statusCode = HTTPStatus.ok;
        res.writeBody("ok", "text/plain");

        return;
    }
}

