module rinha.infra.data_env;

import rinha.core.types;
import std.file : getcwd, exists;
import std.path : buildNormalizedPath, dirName;
import dotenv;
import object : Exception;
import std.stdio : writeln;
import std.process : environment;
import std.exception : enforce;

class DataEnv
{
    //private const string pathFile;

    public immutable(Environment) getEnv() @safe
    {

        Environment envData;

        () @trusted {

          auto appName = environment.get("APP_NAME");
          auto appEnv = environment.get("APP_ENV");
          auto appPort = environment.get("APP_PORT");
          auto appAddress = environment.get("APP_ADDRESS");
          auto logLevel = environment.get("LOG_LEVEL");
          //Env.load(this.pathFile);

          enforce(appName !is null, "APP_NAME não encontrado");
          enforce(appEnv !is null, "APP_ENV não encontrado");
          enforce(appPort !is null, "APP_PORT não encontrado");
          enforce(appAddress !is null, "APP_ADDRESS não encontrado");
          enforce(logLevel !is null, "LOG_LEVEL não encontrado");

          envData.appName = appName;
          envData.appEnv = appEnv;
          envData.appPort = appPort;
          envData.appAddress = appAddress;
          envData.logLevel = appAddress;
        }();

        return envData;
    }
}