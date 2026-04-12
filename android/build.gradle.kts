    // 1. Plugins must be at the very top
    plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    
    // Change 4.4.0 to 4.3.15 as requested by your error log
    id("com.google.gms.google-services") version "4.3.15" apply false
}

    // 2. allprojects handles repositories, NOT plugins/ids
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
    }

    subprojects {
        project.evaluationDependsOn(":app")
    }

    tasks.register<Delete>("clean") {
        delete(rootProject.layout.buildDirectory)
    }