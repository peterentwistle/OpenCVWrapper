import PackageDescription

let package = Package(
    name: "OpenCVWrapper",
	dependencies: [
		.Package(url: "https://github.com/peterentwistle/OpenCVFramework.git", majorVersion: 1)
	]
)
