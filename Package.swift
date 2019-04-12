// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ImageFilters",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "ImageFilters", targets: ["ImageFilters"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "ImageFilters", dependencies: []),
        .testTarget(name: "ImageFiltersTests", dependencies: ["ImageFilters"]),
    ]
)
