// Written in the D programming language.
/**
Haystack zinc encode.

Copyright: Copyright (c) 2017, Radu Racariu <radu.racariu@gmail.com>
License:   $(LINK2 www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
Authors:   Radu Racariu
**/
module haystack.zinc.encode;
import haystack.tag;
import std.range.primitives : isOutputRange;
import std.traits : isSomeChar;

///////////////////////////////////////////////////////////////////
//
// Tag Encoding to Zinc
//
///////////////////////////////////////////////////////////////////
/**
Encodes Marker as 'M'.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Marker), auto ref R writer) if (isOutputRange!(R, char)) 
{  
    writer.put('M');
}
unittest
{
    assert(zinc(Marker()) != "");
    assert(zinc(Marker()) == "M");
}
/**
Encodes Na as 'NA'.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (const Na, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put("NA");
}
unittest
{
    assert(zinc(Na()) == "NA");
    assert(Na().zinc() != "");
}
/**
Encodes Bool as 'T' or 'F'.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (const Bool val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put(val ? 'T' : 'F'); 
    
}
unittest
{
    assert(zinc(Bool(true)) == "T");
    assert(zinc(Bool(false)) == "F");
    assert(zinc(Bool(true)) != "");
}
/**
Encodes Num as 1, -34, 10_000, 5.4e-45, 9.23kg, 74.2°F, 4min, INF, -INF, NaN.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Num) value, auto ref R writer) if (isOutputRange!(R, char))
{ 
    import std.math		: isInfinity, isNaN;
    import std.format	: formattedWrite;

    if (isInfinity(cast(double)value))
    {
        if (value < 0)
            writer.put('-');
        writer.put("INF");
    }
    else if (isNaN(cast(double)value))
    {
        writer.put("NaN");
    }
    else
    {
        formattedWrite(&writer, "%g", value.val);
        if (value.unit.length)
            writer.put(value.unit);
    }
}

unittest
{
    assert(Num(123).zinc() == "123");
    assert(Num(123.4, "s").zinc() == "123.4s");
    assert(Num(1.5e5, "$").zinc() == "150000$");
    assert(Num(1.5e5, "$").zinc() == "150000$");
    assert(Num(1.5e-3, "$").zinc() == "0.0015$");
    assert(Num(-9.9).zinc() == "-9.9");
    assert(Num(double.infinity).zinc() == "INF");
    assert(Num(-1 * double.infinity).zinc() == "-INF");
    assert(Num(double.nan).zinc() == "NaN");
}

/**
Encodes Str as "hello", "foo\nbar\"".
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Str) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put(`"`);
    foreach (dchar c; val)
    {
        if (c >= ' ' && c < 127)
        {
            switch (c)
            {
                case '"':   writer.put(`\"`); break;
                case '\\':  writer.put(`\\`); break;
                case '$':  writer.put(`\$`); break;
                default:
                    writer.put(c);
            }
        }
        else if (c < ' ' || c >= 127)
        {
            switch (c)
            {
                case '\b':  writer.put(`\b`); break;
                case '\f':  writer.put(`\f`); break;
                case '\n':  writer.put(`\n`); break;
                case '\r':  writer.put(`\r`); break;
                case '\t':  writer.put(`\t`); break;
                default:
                    writer.put(`\u`);
                    import std.format : formattedWrite;
                    formattedWrite(&writer, "%04x", c);
            }
        }
    }
    writer.put(`"`);
    
}
unittest
{
    assert(zinc(Str("abc\n")) == `"abc\n"`);
    assert(zinc(Str("a\nb\tfoo")) == `"a\nb\tfoo"`);
    assert(zinc(Str("\u0bae")) == `"\u0bae"`);
    assert(zinc(Str("\\\"")) == `"\\\""`);
    assert(zinc(Str("$")) == `"\$"`);
    assert(zinc(Str("_ \\ \" \n \r \t \u0011 _")) == `"_ \\ \" \n \r \t \u0011 _"`);
}
/**
Encodes XStr as Type("value").
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(XStr) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put(val.type);
    writer.put(`("`);
    writer.put(val.val);
    writer.put(`")`);
    
}
unittest
{
    assert(XStr("Blob", "1-2").zinc() == `Blob("1-2")`);
}
/**
Encodes Uri as `/a/b/c`.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Uri) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put("`");
    foreach (size_t i, dchar c; val.val)
    {
        if (c < ' ')
            continue;
        switch(c)
        {
            case '`' :  writer.put("\\`"); break;
            case '\\' :  writer.put(`\\`); break;
            default:
                if (c >= ' ' && c < 127)
                {
                    writer.put(c);
                }
                else
                {
                    writer.put(`\u`);
                    import std.format : formattedWrite;
                    formattedWrite(&writer, "%04x", c);
                }
        }
    }
    writer.put('`');
    
}
unittest
{
    assert(zinc(Uri(`/a/b/c`)) == "`/a/b/c`");
}
/**
Encodes Ref as @someRef.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Ref) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put('@');
    writer.put(val.val);
    
}
unittest
{
    assert(zinc(Ref("aa-bbc")) == "@aa-bbc");
}
/**
Encodes Date as 2016-12-07 (YYYY-MM-DD).
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Date) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    import std.format	: formattedWrite;
    formattedWrite(&writer, "%02d-%02d-%02d", val.year, val.month, val.day);
    
}
unittest
{
    assert(zinc(Date(2016, 12, 7)) == "2016-12-07");
}
/**
Encodes Time as 08:43:44 (hh:mm:ss.FFF).
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(TimeOfDay) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    import std.format	: formattedWrite;
    formattedWrite(&writer, "%02d:%02d:%02d", val.hour, val.minute, val.second);
    
}
/// ditto
void encode(R) (auto ref const(Time) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    import std.format	: formattedWrite;
    encode(cast(TimeOfDay)val, writer);
    if (val.millis > 0)
        formattedWrite(&writer, ".%03d", val.millis);
    
}
unittest
{
    assert(zinc(TimeOfDay(8, 43, 44)) == "08:43:44");
    assert(zinc(Time(8, 43, 44)) == "08:43:44");
    assert(zinc(Time(23, 59, 59, 999)) == "23:59:59.999");
}

/**
Encodes DateTime as 2009-11-09T15:39:00Z.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(DateTime) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    encode(val.date, writer);
    writer.put('T');
    encode(val.timeOfDay, writer);
    writer.put('Z');
    
}
/**
Encodes SysTime as 2016-13-07T08:56:00-05:00 New_York.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(SysTime) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    import core.time;
    import std.datetime : UTC;
    import std.format	: formattedWrite;
    encode(cast(Date)val, writer);
    writer.put('T');
    encode(cast(TimeOfDay)val, writer);
    if (val.fracSecs > 0.msecs)
        formattedWrite(&writer, ".%03d", val.fracSecs.total!"msecs");
    if (val.timezone == UTC())
    {
        writer.put('Z');
    }
    else
    {
        auto offset = val.utcOffset.split!("hours", "minutes")();
        formattedWrite(&writer, "%s%02d:%02d", offset.hours > 0 ? '+' : '-', offset.hours, offset.minutes);
        import haystack.zinc.tzdata;
        string tzname = getTimeZoneName(val.timezone);
        assert(tzname.length, "Time zone name can't be empty.");
        writer.put(' ');
        writer.put(tzname);
    }   
}
unittest
{
    import core.time;
    assert(zinc(DateTime(Date(2016, 12, 7), Time(8, 56, 00))) == "2016-12-07T08:56:00Z");
    auto e = SysTime(DateTime(Date(2016, 12, 7), Time(8, 56, 00)), 100.msecs).zinc();
    import std.datetime : LocalTime;
    import haystack.zinc.tzdata;
    string tzname = getTimeZoneName(LocalTime());
    assert(e == "2016-12-07T08:56:00.100+02:00 " ~ tzname);
}
/**
Encodes any Tag as zinc.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Tag) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    import std.variant  : VariantN, This;
    import std.traits   : fullyQualifiedName, moduleName;

    // null value
    if (!val.hasValue)
    {
        writer.put('N');
        return;
    }
    immutable isGrid = val.peek!(Grid) !is null;
    if (isGrid)
        writer.put("<<\n");
    Tag value = cast(Tag) val;
    import std.variant : visit;
    // encode current value
    value.visit!(
                    (Marker v) => v.encode(writer),
                    (Na v) => v.encode(writer),
                    (Bool v) => v.encode(writer),
                    (Num v) => v.encode(writer),
                    (Str v) => v.encode(writer),
                    (XStr v) => v.encode(writer),
                    (Uri v) => v.encode(writer),
                    (Ref v) => v.encode(writer),
                    (Date v) => v.encode(writer),
                    (Time v) => v.encode(writer),
                    (DateTime v) => v.encode(writer),
                    (SysTime v) => v.encode(writer),
                    (TagList v) => v.encode(writer),
                    (Dict v) => v.encode(writer),
                    (Grid v) => v.encode(writer)
                    )();

    if (isGrid)
        writer.put("\n>>");
    
}
unittest
{
    assert(Tag().zinc() == "N");
    assert("foo bar".tag.zinc() == `"foo bar"`);
}

/**
Encodes TagList as [1, 2, 3].
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(TagList) val, auto ref R writer) if (isOutputRange!(R, char)) 
{ 
    writer.put('[');
    foreach (size_t i, ref tag; val)
    {
        tag.encode(writer);
        if (i < val.length - 1)
            writer.put(',');
    }
    writer.put(']');
    
}
unittest
{
    auto list = [1.tag, "foo".tag, false.tag];
    assert(list.zinc() == `[1,"foo",F]`);
}
/**
Encodes Dict as  {dis:"Building" site area:35000ft²}.
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Dict) val, auto ref R writer, bool useBraces = true) if (isOutputRange!(R, char)) 
{ 
    if (useBraces)
        writer.put('{');
    size_t i = 0;
    foreach (name, ref value; val)
    {
        writer.put(name);
        if (value.peek!(Marker) is null)
        {
            writer.put(':');
            value.encode(writer);
        }
        if (i++ < val.length - 1)
            writer.put(' ');
    }
    if (useBraces)
        writer.put('}');
    
}
unittest
{
    auto dict = ["marker": marker, "num": 42.tag, "str": "a string".tag];
    assert(dict.zinc() == `{num:42 marker str:"a string"}`);
}
/**
Encodes Grid as ver:"3.0" ... .
Expects an OutputRange as writer.
Returns: the writter OutputRange
*/
void encode(R) (auto ref const(Grid) grid, auto ref R writer) if (isOutputRange!(R, char)) 
{
    writer.put(`ver:"3.0"`);
    if (grid.meta.length > 0)
    {
        writer.put(' ');
        grid.meta.encode(writer, false);
    }
    writer.put('\n');
    if (grid.length == 0)
    {
        writer.put("empty");
        return;
    }
    auto cols = grid.colNames;
    foreach (size_t i, col; cols)
    {
        writer.put(col);
        if (i < cols.length - 1)
            writer.put(',');
    }
    writer.put('\n');
    foreach (size_t rowCnt, ref immutable row; grid)
    {
        foreach (size_t colCnt, col; cols)
        {
            if (row.has(col) && row[col] != Tag.init)
                row[col].encode(writer);
            if (colCnt < cols.length - 1)
                writer.put(',');
        }
        if (rowCnt < grid.length - 1)
            writer.put('\n');
    }
}
unittest
{
    auto expect = "ver:\"3.0\"\n"
                 ~"empty";
    auto empty = Grid([]);
    assert(empty.zinc() == expect);
    // grid of scalars
    auto grid = [
        ["marker": marker, "num": 42.tag, "str": "a string".tag],
        ["marker": marker, "num": 100.tag, "str": "a string".tag]
    ];
    expect = "ver:\"3.0\"\n"
        ~"num,marker,str\n"
        ~`42,M,"a string"` ~ "\n"
        ~`100,M,"a string"`;
    assert(Grid(grid).zinc() == expect);
    // list and dict
    grid =  [
        ["list": [1.tag, true.tag].tag],
        ["dict": ["a": 1.tag, "b": marker()].tag]
    ];
    expect = "ver:\"3.0\"\n"
        ~ "dict,list\n"
        ~ ",[1,T]\n"
        ~ "{b a:1},";
    assert(Grid(grid).zinc() == expect);
    // grid of compound and scalar
    grid =  [
        ["type":"list".tag, "val": [1.tag, 2.tag, 3.tag].tag],
        ["type":"dict".tag, "val": ["dis": "Dict!".tag, "foo": marker].tag],
        ["type":"grid".tag, "val": Grid([["a": 1.tag, "b": 2.tag], ["a": 3.tag, "b": 4.tag]]).tag],
        ["type":"scalar".tag, "val": "a scalar".tag],
    ];
    expect = "ver:\"3.0\"\n"
        ~"val,type\n"
        ~`[1,2,3],"list"` ~ "\n"
        ~`{dis:"Dict!" foo},"dict"` ~ "\n"
        ~"<<\n"
        ~"ver:\"3.0\"\n"
        ~"b,a\n"
        ~"2,1\n"
        ~"4,3\n"
        ~`>>,"grid"` ~ "\n"
        ~`"a scalar","scalar"`;
    auto d = Grid(grid).zinc(); 
    assert(d == expect);
    // meta
    scope metagrid = Grid([["a":1.tag]], ["foo": marker()]);
    expect = `ver:"3.0" foo` ~"\n"
        ~"a\n"
        ~"1";
    d = zinc(metagrid);
    assert(d == expect);
}

private string zinc(T)(auto ref const(T) t)
{
    import std.array : appender;
    auto buf = appender!string();
    static if (is(T == TimeOfDay))
    {
        scope Tag tag = Time(t);
        tag.encode(buf);
    }
    else static if (is(T == DateTime))
    {
        import std.datetime : UTC;
        scope Tag tag = SysTime(t, UTC());
        tag.encode(buf);
    }
    else static if (is(T == Grid))
    {
        t.encode(buf);
    }
    else
    {
        t.encode(buf);
    }
    return buf.data;
}