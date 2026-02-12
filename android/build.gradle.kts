import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
// Avoid importing Kotlin JVM DSL types that may be unavailable in some plugin versions

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Ensure every subproject has a coreLibraryDesugaring configuration with the desugar libs dependency
subprojects {
    try {
        val cfg = configurations.findByName("coreLibraryDesugaring") ?: configurations.create("coreLibraryDesugaring")
        if (cfg.dependencies.isEmpty()) {
            dependencies.add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.3")
        }
    } catch (_: Exception) {
        // ignore if configurations are not available for this project
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Workaround for plugins that haven't migrated to namespace-based build (AGP 8.0+)
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null && android.namespace == null) {
                // Use the package name from manifest if available, or fallback to project name
                android.namespace = project.group.toString().takeIf { it.isNotEmpty() } 
                    ?: "dev.isar.${project.name.replace("-", "_")}"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Java/Kotlin compilation targets are controlled per-module (app/build.gradle.kts)
// Configure Android modules to use Java 17 and configure Kotlin JVM toolchain when Kotlin plugin is applied
subprojects {
    pluginManager.withPlugin("com.android.application") {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        try {
            androidExt?.compileOptions?.apply {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
                isCoreLibraryDesugaringEnabled = true
            }
        } catch (_: Exception) {
            // Property already finalized by the module; skip
        }
    }
    pluginManager.withPlugin("com.android.library") {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        try {
            androidExt?.compileOptions?.apply {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
                isCoreLibraryDesugaringEnabled = true
            }
        } catch (_: Exception) {
            // Property already finalized by the module; skip
        }
        try {
            val libExt = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            libExt?.defaultConfig?.multiDexEnabled = true
        } catch (_: Exception) {
            // ignore if not available or already configured
        }
    }

    // Configure Kotlin JVM toolchain if Kotlin plugin applied
    pluginManager.withPlugin("org.jetbrains.kotlin.android") {
        val kotlinExt = extensions.findByType(KotlinJvmProjectExtension::class.java)
        kotlinExt?.jvmToolchain(17)
    }
    pluginManager.withPlugin("org.jetbrains.kotlin.jvm") {
        val kotlinExt = extensions.findByType(KotlinJvmProjectExtension::class.java)
        kotlinExt?.jvmToolchain(17)
    }
    // Also handle legacy plugin ids
    pluginManager.withPlugin("kotlin-android") {
        val kotlinExt = extensions.findByType(KotlinJvmProjectExtension::class.java)
        kotlinExt?.jvmToolchain(17)
    }
    pluginManager.withPlugin("kotlin") {
        val kotlinExt = extensions.findByType(KotlinJvmProjectExtension::class.java)
        kotlinExt?.jvmToolchain(17)
    }

    // Force Kotlin compilation target to Java 17 to avoid inconsistent JVM-target errors.
    try {
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            try {
                val kotlinCompile = this as org.jetbrains.kotlin.gradle.tasks.KotlinCompile
                try {
                    val getCompilerOptions = kotlinCompile::class.java.getMethod("getCompilerOptions")
                    val compilerOptions = getCompilerOptions.invoke(kotlinCompile)
                    try {
                        // Newer Kotlin DSL: compilerOptions.getJvmTarget().set("17")
                        val jvmTargetProp = compilerOptions::class.java.getMethod("getJvmTarget").invoke(compilerOptions)
                        val setMethod = jvmTargetProp::class.java.getMethod("set", Any::class.java)
                        setMethod.invoke(jvmTargetProp, "17")
                    } catch (_: Exception) {
                        // Older shape: compilerOptions.setJvmTarget(String)
                        try {
                            val setMethod2 = compilerOptions::class.java.getMethod("setJvmTarget", String::class.java)
                            setMethod2.invoke(compilerOptions, "17")
                        } catch (_: Exception) {
                            // ignore
                        }
                    }
                } catch (_: NoSuchMethodException) {
                    // Fallback to legacy kotlinOptions
                    try {
                        val ko = kotlinCompile::class.java.getMethod("getKotlinOptions").invoke(kotlinCompile)
                        val jvmSet = ko::class.java.getMethod("setJvmTarget", String::class.java)
                        jvmSet.invoke(ko, "17")
                    } catch (_: Exception) {
                        // ignore
                    }
                }
            } catch (_: Exception) {
                // ignore any other issues
            }
        }
    } catch (_: Exception) {
        // ignore if tasks API not available
    }

    // Ensure library and plugin modules that enable coreLibraryDesugaring get the desugar libs dependency
    try {
        val cfg = project.configurations.findByName("coreLibraryDesugaring")
        if (cfg != null && cfg.dependencies.isEmpty()) {
            project.dependencies.add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.3")
        }
    } catch (_: Exception) {
        // Configurations may not be ready yet. If the project hasn't been evaluated, schedule the same action safely.
        try {
            if (!project.state.executed) {
                project.afterEvaluate {
                    try {
                        val cfg2 = project.configurations.findByName("coreLibraryDesugaring")
                        if (cfg2 != null && cfg2.dependencies.isEmpty()) {
                            project.dependencies.add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.3")
                        }
                    } catch (_: Exception) {}
                }
            } else {
                // already executed and couldn't access configurations; give up silently
            }
        } catch (_: Exception) {
            // project.state may be inaccessible on older Gradle; ignore
        }
    }
}
