$SDK = "C:\Users\chromedays\scoop\apps\android-sdk\current"
$BUILD_TOOLS = "$SDK\build-tools\30.0.2"
$PLATFORM = "$SDK\platforms\android-29"
# $API = 29
$APK = "vkand"
$PACKAGE = "com.vkand"
$ORG_DIRS = "com\vkand"
$NDK = "$SDK\ndk\22.0.6917172"
$CLANG = "$NDK\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android29-clang.cmd"
$AR = "$NDK\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android-ar.exe"
$KEYSTORE = "debugkeystore.jks"

function Build {
    mkdir -Force -p "build\apk" > $null
    # mkdir -Force -p "build\gen" > $null
    mkdir -Force -p "build\obj" > $null
    mkdir -Force -p "build\apk\lib\arm64-v8a" > $null

    # echo "Executing aapt"
    # & "$BUILD_TOOLS\aapt" package -f -m -J "build\gen\" -S res -M AndroidManifest.xml -I "$PLATFORM\android.jar"
    # & javac -bootclasspath "$env:JAVA_HOME\jre\lib\rt.jar" -classpath "$PLATFORM\android.jar" -d "build\obj" "build\gen\$ORG_DIRS\R.java" "src\$ORG_DIRS\MainActivity.java"
    # & javah -classpath "$PLATFORM\android.jar;build\obj" -o "build\tmp\jni.h" "$PACKAGE.MainActivity"
    echo "Compiling to libandroid_native_app_glue.so"
    & $CLANG -c -g -o "build\obj\android_native_app_glue.o" "$NDK\sources\android\native_app_glue\android_native_app_glue.c"
    # & $AR -rc libandroid_native_app_glue.a "build\apk\lib\arm64-v8a\android_native_app_glue.o"
    & $AR -rc "build\apk\lib\arm64-v8a\libandroid_native_app_glue.a" "build\obj\android_native_app_glue.o"
    echo "Compiling to libhello.so"
    & $CLANG -shared -g -o "build\apk\lib\arm64-v8a\libhello.so" "src\$ORG_DIRS\hello.c" -I"$NDK\sources\android\native_app_glue" -L"build\apk\lib\arm64-v8a" -landroid_native_app_glue  -llog -landroid -lEGL -lGLESv2
    # echo "DX"
    # & "$BUILD_TOOLS\dx" --dex --output="build\apk\classes.dex" "build\obj"
    echo "Executing aapt again"
    & "$BUILD_TOOLS\aapt" package -f -A assets -M AndroidManifest.xml -I "$PLATFORM\android.jar" -F "build\$APK.unsigned.apk" "build\apk"
    echo "Executing zipalign"
    & "$BUILD_TOOLS\zipalign" -f -p 4 "build\$APK.unsigned.apk" "build\$APK.aligned.apk"
    if (!(Test-Path -path $KEYSTORE)) {
        echo "Executing keytool"
        & keytool -genkeypair -keystore $KEYSTORE -dname "CN=Android Debug, O=Android, C=US" -keypass android -storepass android -alias androiddebugkey -validity 10000 -keyalg RSA -keysize 2048
    }
    echo "Executing apksigner"
    & "$BUILD_TOOLS\apksigner" sign --ks $KEYSTORE --ks-key-alias androiddebugkey --ks-pass "pass:android" --out "build\$APK.apk" "build\$APK.aligned.apk"
}

function Clean
{
    if (Test-Path -path build) {
        Remove-Item -Recurse -Force -Confirm:$false build
    }
}

function Inspect {
    & "$BUILD_TOOLS\aapt" list -v "build\$APK.apk"
}

function Install {
    & adb install -r "build\$APK.apk"
}

function Launch {
    & adb shell am start --activity-clear-top -n "$PACKAGE/android.app.NativeActivity"
}

if ($args[0] -eq $null) {
echo @"
Usage: $($MyInvocation.MyCommand.Name) [command]

[command] can be:
    run       - install and run .apk file
    build     - build .apk file
    uninstall - uninstall installed .apk
    install   - install .apk file on connected device
    launch    - run already installed .apk file
    log       - show logcat
    inspect   - inspect .apk file
    clean     - clean build result
"@
} else {
    switch -Exact ($args[0]) {
        "run"
        {
            Install
            Launch
        }
        "build"
        {
            Build
        }
        "uninstall"
        {
            & adb uninstall $PACKAGE
        }
        "install"
        {
            Install
        }
        "launch"
        {
            Launch
        }
        "log"
        {
            iex "adb logcat $($PACKAGE):V *:S"
        }
        "inspect"
        {
            Inspect
        }
        "clean"
        {
            Clean
        }
    }
}

# & "$BUILD_TOOLS\aapt" package -f -m -J "build\gen\" -S res -M AndroidManifest.xml -I "$PLATFORM\android.jar"
# & javac -bootclasspath "$env:JAVA_HOME\jre\lib\rt.jar" -classpath "$PLATFORM\android.jar" -d "build\obj" "build\gen\$ORG_DIRS\R.java" "src\$ORG_DIRS\MainActivity.java"
# & javah -classpath "$PLATFORM\android.jar;build\obj" -o "build\tmp\jni.h" "$PACKAGE.MainActivity"
# & $CLANG -shared -o "build\apk\lib\arm64-v8a\libhello.so" "src\$ORG_DIRS\hello.c"
# & "$BUILD_TOOLS\dx" --dex --output="build\apk\classes.dex" "build\obj"
# & "$BUILD_TOOLS\aapt" package -f -S res -M AndroidManifest.xml -I "$PLATFORM\android.jar" -F "build\$APK.unsigned.apk" "build\apk"
# & "$BUILD_TOOLS\zipalign" -f -p 4 "build\$APK.unsigned.apk" "build\$APK.aligned.apk"
# & keytool -genkeypair -keystore keystore.jks -alias androidkey -validity 10000 -keyalg RSA -keysize 2048
