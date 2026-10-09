import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, never committed (`key.properties`, `*.jks` are gitignored).
// Source 1: `android/key.properties` (local machine). Source 2: environment variables (CI).
// See `DOCS/android-release-signing.md`.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingValue(propertyKey: String, envKey: String): String? =
    (keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "MEDIAVORE_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "MEDIAVORE_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "MEDIAVORE_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "MEDIAVORE_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword,
).all { it != null }

// Opt-in escape hatch for local `flutter run --release` without the upload key:
// `ORG_GRADLE_PROJECT_mediavoreAllowDebugSigning=true` (or `~/.gradle/gradle.properties`).
// Never set it in CI: the resulting APK/AAB is signed with the public debug key.
val allowDebugSigning = (findProperty("mediavoreAllowDebugSigning") as String?).toBoolean()

android {
    namespace = "fr.zimberts.mediavore"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "fr.zimberts.mediavore"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                // Relative paths resolve against `android/app/`, as in Flutter's template.
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseSigning -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

// Fail fast instead of silently producing a debug-signed or unsigned release artifact.
// Checked on the task graph, not at configuration time, so debug builds never need the key.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (buildsRelease && !hasReleaseSigning) {
        if (allowDebugSigning) {
            logger.warn(
                "WARNING: release build signed with the DEBUG key (mediavoreAllowDebugSigning=true). " +
                    "Do not distribute this artifact.",
            )
        } else {
            throw GradleException(
                "Release signing is not configured. Provide android/key.properties or the " +
                    "MEDIAVORE_KEYSTORE_PATH / MEDIAVORE_KEYSTORE_PASSWORD / MEDIAVORE_KEY_ALIAS / " +
                    "MEDIAVORE_KEY_PASSWORD environment variables (see DOCS/android-release-signing.md). " +
                    "For a local-only test, set ORG_GRADLE_PROJECT_mediavoreAllowDebugSigning=true.",
            )
        }
    }
}

// 16 KB page size (Android 15+ / Google Play): `androidx.datastore` 1.2.0 ships a
// `libdatastore_shared_counter.so` whose RELRO segment is not 16 KB aligned
// (flutter/flutter#182744), which fails Play's ELF alignment check. Version 1.1.7
// is the known-good release, and `shared_preferences_android` already requests it —
// force it across the graph so a transitive bump cannot silently regress us.
configurations.all {
    resolutionStrategy {
        force("androidx.datastore:datastore:1.1.7")
        force("androidx.datastore:datastore-core:1.1.7")
        force("androidx.datastore:datastore-preferences:1.1.7")
    }
}

flutter {
    source = "../.."
}
