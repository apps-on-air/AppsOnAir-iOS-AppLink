// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppsOnAir-AppLink",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AppsOnAir_AppLink",
            targets: ["AppsOnAir_AppLink", "AppsOnAirAppLinkObjC"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apps-on-air/AppsOnAir-iOS-Core.git",
            exact: "1.2.1"
        )
    ],
    targets: [
        .target(
            name: "AppsOnAir_AppLink",
            dependencies: [
                .product(name: "AppsOnAir-Core", package: "AppsOnAir-iOS-Core")
            ],
            path: "AppsOnAir_AppLink",
            resources: [
                .process("Resources/AppsOnAir-AppLinkInfo.plist")
            ]
        ),
        .target(
            name: "AppsOnAirAppLinkObjC",
            dependencies: ["AppsOnAir_AppLink"],
            path: "AppsOnAir_AppLink_ObjC",
            publicHeadersPath: "include"
        ),
    ]
)
