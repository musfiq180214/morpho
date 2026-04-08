
project.afterEvaluate {
    tasks.filter { it.name.startsWith("compileFlutterBuild") }.forEach { task ->
        val flavor = task.name.substringAfter("compileFlutterBuild").lowercase()
        if (flavor.contains("staging")) {
            (task as? com.flutter.gradle.tasks.FlutterTask)?.let { it.targetPath = "lib/main_staging.dart" }
        } else if (flavor.contains("production")) {
            (task as? com.flutter.gradle.tasks.FlutterTask)?.let { it.targetPath = "lib/main_production.dart" }
        }
    }
}
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.morpho"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.morpho"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions.add("app")



    productFlavors {
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Morpho Staging")
        }
        create("production") {
            dimension = "app"
            resValue("string", "app_name", "Morpho")
        }
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
