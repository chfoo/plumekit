package plumekit.internal;


class ResourceSetup {
    public static function initResources() {
        #if !embed_resources
        return;
        #elseif macro
        EncodingsResource.embedEncodings();
        EncodingsResource.embedIndexes();
        UnicodeResource.embedUnicodeData();
        UnicodeResource.embedIDNA();
        UnicodeResource.embedDerivedJoiningType();
        UnicodeResource.embedScripts();
        #end
    }
}
