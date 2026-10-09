import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.mmdigital.vaktinde"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mmdigital.vaktinde"
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8: Kotlin/Java kodu küçültülür, optimize edilir ve karartılır (Play "DEX kodu
            // optimizasyonu" ölçütü). Eşleme dosyası AAB'ye girer, Crashlytics'e de yüklenir.
            // Kurallar: proguard-rules.pro (bildirim eklentisinin Gson kayıtları)
            isMinifyEnabled = true
            // Kaynak küçültme (Play "kullanılmayan kaynaklar"; varsayılan güvenli kip): Dart'tan
            // adla çağrılan kaynaklar (res/raw ezan/bildirim sesleri, '@mipmap/launcher_icon'
            // bildirim simgesi) küçültücüye görünmez, res/raw/keep.xml (tools:keep) ile korunur
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}