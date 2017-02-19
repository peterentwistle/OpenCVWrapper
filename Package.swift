import PackageDescription

let package = Package(
    name: "OpenCVWrapper",
	dependencies: [
		.Package(url: "https://github.com/peterentwistle/OpenCVFramework.git", majorVersion: 1),
		.Package(url: "https://github.com/peterentwistle/EmotionCore.git", majorVersion: 1)
	]
)
