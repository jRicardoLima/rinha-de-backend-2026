module rinha.utils.helpers;

import std.datetime;
import vibe.data.json : Json;
import std.exception;

long convertToTimestamp(scope const(char[]) dateTime) @trusted
{
    SysTime dateTimeParse = SysTime.fromISOExtString(dateTime);

    return dateTimeParse.toUnixTime();
}

int convertTimestampToMinutes(const(long) timestamp) @trusted
{
    SysTime dateTimeParse = SysTime.fromUnixTime(timestamp,UTC());

    return dateTimeParse.minute;
}

int convertTimestampToHours(const(long) timestamp) @trusted
{
    SysTime dateTimeParse = SysTime.fromUnixTime(timestamp,UTC());

    return dateTimeParse.hour;
}

int convertTimestampToDayOfWeek(const(long) timestamp) @trusted
{
    SysTime dateTimeParse = SysTime.fromUnixTime(timestamp,UTC());

    return (cast(int) dateTimeParse.dayOfWeek + 6) % 7;
}

double jsonNumberAsDouble(Json value, string fieldName) @safe
{
    switch(value.type()) {
        case Json.Type.int_ :
            return cast(double) value.get!long;
        case Json.Type.float_ :
            return value.get!double;
        default:
            throw new Exception("Field " ~ fieldName ~ " must be numeric");
    }
}

float jsonNumberAsFloat(Json value, string fieldName) @safe
{
    return cast(float) jsonNumberAsDouble(value, fieldName);
}