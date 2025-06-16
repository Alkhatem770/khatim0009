// Top-level build file where you can add configuration options common to all sub-projects/modules.

// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    dependencies {
        // START: FlutterFire Configuration
        classpath("com.google.gms:google-services:4.3.15")
        // END: FlutterFire Configuration
        classpath 'dev.flutter:flutter-gradle-plugin:1.0.0'
    }
}

plugins {
    id "com.android.application" apply false
    id "org.jetbrains.kotlin.android" apply false
    id "com.google.gms.google-services" version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// تغيير مسار build directory ليكون خارج مجلد android
def newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    def newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// اجبار التقييم لتطبيق ":app"
subprojects {
    project.evaluationDependsOn(":app")
}

// مهمة تنظيف المشروع
tasks.register("clean", Delete) {
    delete(rootProject.layout.buildDirectory)
}