// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ios-bookshelf-scanner",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ios-bookshelf-scanner", targets: ["ios-bookshelf-scanner"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .target(
            name: "ios-bookshelf-scanner",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Sources",
            exclude: ["ios_bookshelf_scannerApp.swift"]
        ),
        .executableTarget(
            name: "ios-bookshelf-scanner-app",
            dependencies: ["ios-bookshelf-scanner"],
            path: "Sources",
            sources: ["ios_bookshelf_scannerApp.swift"]
        )
    ]
)