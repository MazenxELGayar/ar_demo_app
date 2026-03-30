import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

    buildDir = file("${rootProject.buildDir}/${name}")

    plugins.withId("com.android.application") {
        configureAndroid()
    }

    plugins.withId("com.android.library") {
        configureAndroid()
    }

    evaluationDependsOn(":app")
}

fun Project.configureAndroid() {
    extensions.configure<BaseExtension>("android") {

        if (namespace == null) {
            namespace = project.group.toString()
        }

        compileSdkVersion(36)

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
