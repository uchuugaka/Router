import PackageDescription

let package = Package(
	name: "Router",
	dependencies: [
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 1)
	]
)
