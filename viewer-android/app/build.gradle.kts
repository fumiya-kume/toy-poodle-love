plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
    alias(libs.plugins.secrets)
    alias(libs.plugins.kover)
}

android {
    namespace = "com.fumiyakume.viewer"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.fumiyakume.viewer"
        minSdk = 28
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

secrets {
    propertiesFileName = "local.properties"
    defaultPropertiesFileName = "local.defaults.properties"
}

dependencies {
    // Core
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)

    // Compose
    implementation(platform(libs.compose.bom))
    implementation(libs.bundles.compose)
    debugImplementation(libs.compose.ui.tooling)

    // Hilt DI
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Networking
    implementation(libs.bundles.networking)

    // Video Player
    implementation(libs.bundles.media3)

    // Maps
    implementation(libs.bundles.maps)

    // Local Storage
    implementation(libs.datastore.preferences)

    // Lifecycle & Navigation
    implementation(libs.bundles.lifecycle)
    implementation(libs.navigation.compose)

    // Coroutines
    implementation(libs.coroutines.core)
    implementation(libs.coroutines.android)

    // Image Loading
    implementation(libs.coil.compose)

    // Testing
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.bundles.testing)
    testImplementation(libs.compose.ui.test)
    testImplementation(libs.robolectric)
    androidTestImplementation(libs.bundles.androidTesting)
    androidTestImplementation(platform(libs.compose.bom))
    debugImplementation(libs.compose.ui.test.manifest)
}

kover {
    reports {
        filters {
            excludes {
                classes(
                    "com.fumiyakume.viewer.BuildConfig",
                    "com.fumiyakume.viewer.R",
                    "com.fumiyakume.viewer.R\$*",
                    "com.fumiyakume.viewer.MainActivity*",
                    "com.fumiyakume.viewer.ComposableSingletons*",
                    "com.fumiyakume.viewer.core.di.*",
                    "com.fumiyakume.viewer.*_Factory*",
                    "com.fumiyakume.viewer.*_Hilt*",
                    "com.fumiyakume.viewer.Hilt_*",
                    "com.fumiyakume.viewer.*_MembersInjector*",
                    "dagger.hilt.internal.aggregatedroot.codegen.*",
                    "hilt_aggregated_deps.*"
                )
            }
        }
    }
}
