plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "io.github.andi_0309.easyhof"
    compileSdk = 36
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "io.github.andi_0309.easyhof"
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    flavorDimensions += "device"
    productFlavors {
        create("phone") { dimension = "device" }
        create("wear") { dimension = "device"; minSdk = 30 }
    }
    signingConfigs {
        if (System.getenv("KEYSTORE_PATH") != null) {
            create("production") {
                storeFile = file(System.getenv("KEYSTORE_PATH"))
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("production") ?: signingConfigs.getByName("debug")
        }
    }
}
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
flutter { source = "../.." }
dependencies {
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    "wearImplementation"("androidx.health:health-services-client:1.1.0")
    "wearImplementation"("com.google.guava:guava:33.4.8-android")
    "phoneImplementation"("androidx.health.connect:connect-client:1.1.0")
    "phoneImplementation"("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16.1")
}
android.testOptions.unitTests.isIncludeAndroidResources = true

// AGP 9 host-test packaging consumes Flutter assets. Flutter's plugin does
// not currently register this dependency for the host-test packaging task.
tasks.configureEach {
    if (name.startsWith("package") && name.endsWith("UnitTestForUnitTest")) {
        val variant = name.removePrefix("package").removeSuffix("UnitTestForUnitTest")
        dependsOn("copyFlutterAssets$variant")
    }
}
