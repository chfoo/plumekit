package plumekit.text.codec;

import plumekit.Exception;
import plumekit.text.codec.EncodingsLoader;

using StringTools;


class Registry {
    static var labelToNameMap:Map<String,String>;
    static var nameInfoMap:Map<String,EncodingNameInfo>;

    public static function getEncodingName(label:String):String {
        initMaps();

        var normalizedLabel = label.trim().toLowerCase();

        if (labelToNameMap.exists(normalizedLabel)) {
            return labelToNameMap.get(normalizedLabel);
        } else {
            throw new ValueException('Encoding for label $label not found.');
        }
    }

    public static function getOutputEncodingName(encodingName:String):String {
        switch (encodingName) {
            case "replacement" | "UTF-16BE" | "UTF-16LE":
                return "UTF-8";
            default:
                return encodingName;
        }
    }

    public static function getEncoderHandler(label:String):Handler {
        initMaps();

        var name = getEncodingName(label);
        var heading = nameInfoMap.get(name).heading;

        switch (heading) {
            case "The Encoding":
                return new UTF8Encoder();
            case "Legacy single-byte encodings":
                return new SingleByteEncoder(name.toLowerCase());
            case "Legacy multi-byte Chinese (simplified) encodings":
                return new GB18030Encoder(name == "GBK");
            case "Legacy multi-byte Chinese (traditional) encodings":
                return new Big5Encoder();
            case "Legacy multi-byte Japanese encodings":
                switch (name) {
                    case "EUC-JP":
                        return new EUCJPEncoder();
                    case "ISO-2022-JP":
                        return new ISO2022JPEncoder();
                    case "Shift_JIS":
                        return new ShiftJISEncoder();
                    default:
                        throw "Shouldn't reach here";
                }
            case "Legacy multi-byte Korean encodings":
                return new EUCKREncoder();
            default:
                switch (name) {
                    case "replacement" | "UTF-16BE" | "UTF-16LE":
                        throw new ValueException('Encoding $name does not have an associated encoder.');
                    case "x-user-defined":
                        return new XUserDefinedEncoder();
                    default:
                        throw new ValueException('Unsupported encoding $name.');
                }
        }
    }

    public static function getDecoderHandler(label:String):Handler {
        initMaps();

        var name = getEncodingName(label);
        var heading = nameInfoMap.get(name).heading;

        switch (heading) {
            case "The Encoding":
                return new UTF8Decoder();
            case "Legacy single-byte encodings":
                return new SingleByteDecoder(name.toLowerCase());
            case "Legacy multi-byte Chinese (simplified) encodings":
                return new GB18030Decoder();
            case "Legacy multi-byte Chinese (traditional) encodings":
                return new Big5Decoder();
            case "Legacy multi-byte Japanese encodings":
                switch (name) {
                    case "EUC-JP":
                        return new EUCJPDecoder();
                    case "ISO-2022-JP":
                        return new ISO2022JPDecoder();
                    case "Shift_JIS":
                        return new ShiftJISDecoder();
                    default:
                        throw "Shouldn't reach here";
                }
            case "Legacy multi-byte Korean encodings":
                return new EUCKRDecoder();
            default:
                switch (name) {
                    case "replacement":
                        return new ReplacementDecoder();
                    case "UTF-16BE" | "UTF-16LE":
                        return new UTF16Decoder(name == "UTF-16BE");
                    case "x-user-defined":
                        return new XUserDefinedDecoder();
                    default:
                        throw new ValueException('Unsupported encoding $name.');
                }
        }
    }

    static function initMaps() {
        if (labelToNameMap != null) {
            return;
        }

        labelToNameMap = EncodingsLoader.getLabelsToEncodingNameMap();
        nameInfoMap = EncodingsLoader.getEncodingNameInfos();
    }

    public static function getEncoder(encoding:String = "utf-8", ?errorMode:ErrorMode):Encoder {
        var encoderHandler = Registry.getEncoderHandler(encoding);
        var encoder = new EncoderRunner(encoderHandler, errorMode);

        return encoder;
    }

    public static function getDecoder(encoding:String = "utf-8", ?errorMode:ErrorMode):Decoder {
        var decoderHandler = Registry.getDecoderHandler(encoding);
        var decoder = new DecoderRunner(decoderHandler, errorMode);

        return decoder;
    }
}
