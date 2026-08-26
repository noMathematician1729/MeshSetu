// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audioplayers_darwin", path: "../.packages/audioplayers_darwin-6.5.0"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-13.2.0"),
        .package(name: "flutter_foreground_task", path: "../.packages/flutter_foreground_task-11.0.1"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.0"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.4.0"),
        .package(name: "mobile_scanner", path: "../.packages/mobile_scanner-7.4.0"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.6.1"),
        .package(name: "record_ios", path: "../.packages/record_ios-2.1.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sherpa_onnx_ios", path: "../.packages/sherpa_onnx_ios-1.13.5"),
        .package(name: "universal_ble", path: "../.packages/universal_ble"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audioplayers-darwin", package: "audioplayers_darwin"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "flutter-foreground-task", package: "flutter_foreground_task"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "mobile-scanner", package: "mobile_scanner"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "record-ios", package: "record_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sherpa-onnx-ios", package: "sherpa_onnx_ios"),
                .product(name: "universal-ble", package: "universal_ble"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
