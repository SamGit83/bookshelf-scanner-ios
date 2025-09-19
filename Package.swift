// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ios-bookshelf-scanner",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "BookshelfScanner", targets: ["BookshelfScannerApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "BookshelfScannerApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Sources/BookshelfScannerApp",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)