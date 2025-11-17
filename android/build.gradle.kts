allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use absolute path to avoid issues with spaces in path
val projectRoot = rootProject.projectDir.parentFile
val buildDirPath = File(projectRoot, "build").absolutePath
rootProject.layout.buildDirectory.set(File(buildDirPath))

subprojects {
    val subprojectBuildDir = File(buildDirPath, project.name).absolutePath
    project.layout.buildDirectory.set(File(subprojectBuildDir))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
