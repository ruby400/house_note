plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ 실제 적용해야 함 (apply false 제거!)
}

android {
    namespace = "com.ruby444.house_note"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.ruby444.house_note"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BOM: 버전 충돌 방지
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))

    // ✅ 원하는 Firebase 모듈 추가 (예: Analytics)
    implementation("com.google.firebase:firebase-analytics")

    // 🔥 추가적으로 쓰고 싶은 기능이 있다면 아래처럼 추가
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}