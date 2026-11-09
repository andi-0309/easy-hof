# Conscrypt includes adapters for Android versions older than our minSdk 28.
# Their hidden platform classes are intentionally absent from the public SDK.
-dontwarn com.android.org.conscrypt.SSLParametersImpl
-dontwarn org.apache.harmony.xnet.provider.jsse.SSLParametersImpl

# LibADB loads this provider and TLS exporter through reflection.
-keep class org.conscrypt.OpenSSLProvider { public <init>(); }
-keep class org.conscrypt.Conscrypt {
    public static byte[] exportKeyingMaterial(javax.net.ssl.SSLSocket, java.lang.String, byte[], int);
}
