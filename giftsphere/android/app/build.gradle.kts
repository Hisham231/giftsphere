plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ربط الفايربيس
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.giftsphere"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🚨 تعديل: توحيد الإصدار إلى Java 17 لحل تعارض الـ JVM
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // 🚨 تعديل: توحيد الـ jvmTarget ليتوافق مع الـ Compile Options
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.giftsphere"
        
        // 🚨 الـ minSdk 23 ضروري جداً لعمل مكتبة fast_contacts
        minSdk = flutter.minSdkVersion 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 💡 إضافة هذا الجزء لضمان استخدام Java 17 في بناء الكوتلن أيضاً
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}

dependencies {
    // مكتبات الفايربيس الأساسية (تأكد من تحديث النسخة لـ 33.0.0 لتوافق أفضل)
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
}
