// swift-tools-version: 6.1
//
//  Package.swift
//  TalyaDemo
//
//  Created by liusilan on 2025/9/7.
//

import Foundation

import PackageDescription

let package = Package(
    name: "TalyaDemo",
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.19"))
    ],
    targets: [
        .target(
        name: "TalyaDemo",
        dependencies: ["ZIPFoundation"]),
    ]
)
