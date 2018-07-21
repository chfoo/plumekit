package plumekit.url;


class IPv4Serializer {
    public static function serialize(address:Int):String {
        // This algorithm deviates from the spec for the sake of conciseness
        var part1 = Std.string((address >> 24) & 0xff);
        var part2 = Std.string((address >> 16) & 0xff);
        var part3 = Std.string((address >> 8) & 0xff);
        var part4 = Std.string(address & 0xff);

        return '$part1.$part2.$part3.$part4';
    }
}
