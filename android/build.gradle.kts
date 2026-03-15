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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Workaround for plugins that haven't migrated to namespace-based build (AGP 8.0+)
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                // Force compileSdk to a recent version to avoid Android resource linking errors (e.g., lStar not found)
                android.compileSdkVersion(36)

                if (android.namespace == null) {
                    // Use the package name from manifest if available, or fallback to project name
                    android.namespace = project.group.toString().takeIf { it.isNotEmpty() }
                        ?: "dev.isar.${project.name.replace("-", "_")}"
                }
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
