# SwiftGit2

> [!WARNING]
> The SwiftGit2 maintainers are in the process of migrating SwiftGit2 to the Swift Package Manager.
> 
> This causes the following breaking changes:
>
> * The Carthage configuration and Xcode project are gone and are longer supported.
> * SwiftGit2 must now be explicitly initialized by the application by calling `SwiftGit2Init()`. Its resources may be cleaned up again using `SwiftGit2Shutdown()`.
> * SSH remotes on iOS require the `LibSSH2` trait, see [Choosing the HTTPS and SSH backends](#choosing-the-https-and-ssh-backends).

[![Build Status](https://github.com/SwiftGit2/SwiftGit2/actions/workflows/BuildPR.yml/badge.svg)](https://github.com/SwiftGit2/SwiftGit2/actions)
[![GitHub release](https://img.shields.io/github/release/SwiftGit2/SwiftGit2.svg)](https://github.com/SwiftGit2/SwiftGit2/releases)
![Swift 5.9.x](https://img.shields.io/badge/Swift-5.9.x-orange.svg)

Swift bindings to [libgit2](https://github.com/libgit2/libgit2).

```swift
let URL: URL = ...
let result = Repository.at(URL)
switch result {
case let .success(repo):
    let latestCommit = repo
        .HEAD()
        .flatMap {
            repo.commit($0.oid)
        }

    switch latestCommit {
    case let .success(commit):
        print("Latest Commit: \(commit.message) by \(commit.author.name)")

    case let .failure(error):
        print("Could not get commit: \(error)")
    }

case let .failure(error):
    print("Could not open repository: \(error)")
}
```

## Design

SwiftGit2 uses value types wherever possible. That means using Swift’s `struct`s and `enum`s without holding references to libgit2 objects. This has a number of advantages:

1. Values can be used concurrently.
2. Consuming values won’t result in disk access.
3. Disk access can be contained to a smaller number of APIs.

This vastly simplifies the design of long-lived applications, which are the most common use case with Swift. Consequently, SwiftGit2 APIs don’t necessarily map 1-to-1 with libgit2 APIs.

All methods for reading from or writing to a repository are on SwiftGit’s only `class`: `Repository`. This highlights the failability and mutation of these methods, while freeing up all other instances to be immutable `struct`s and `enum`s.

## Adding SwiftGit2 to your Project

You can add SwiftGit2 to your project using the [Swift Package Manager](https://www.swift.org/documentation/package-manager/).

In Xcode, go to your project settings, then to `Package Dependencies`. Add SwiftGit2 using the URL:

```
https://github.com/SwiftGit2/SwiftGit2.git
```

If you're developing an SPM-based project, open your `Package.swift` file and add SwiftGit2 as a dependency:

```swift
.package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0")
```

And don't forget to reference it from your target:

```swift
.target(name: "YourProject", dependencies: ["SwiftGit2"]),
```

### Choosing the HTTPS and SSH backends

By default SwiftGit2 talks HTTPS through Apple's Security framework and SSH by running the system `ssh` executable, which means SSH remotes do not work on iOS. Enable the `OpenSSL` and `LibSSH2` [package traits](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0450-swiftpm-package-traits.md) to link precompiled [OpenSSL](https://github.com/mbernson/OpenSSL-Apple) and [libssh2](https://github.com/mbernson/libssh2-Apple) instead. This requires Swift 6.1 (Xcode 16.3) or later.

```swift
// HTTPS through OpenSSL, SSH through libssh2 (works on iOS):
.package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0", traits: ["LibSSH2"])

// HTTPS through OpenSSL, SSH through the system ssh executable:
.package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0", traits: ["OpenSSL", "SSHExec"])
```

libgit2 compiles exactly one backend of each kind, so listing traits replaces the defaults rather than adding to them. The available traits are `SecureTransport` (default), `OpenSSL`, `SSHExec` (default) and `LibSSH2`, where `LibSSH2` implies `OpenSSL`.

OpenSSL cannot use the system keychain to verify server certificates. On macOS it reads the system CA bundle at `/etc/ssl/cert.pem`. iOS has no CA bundle on disk, so an app using the `OpenSSL` or `LibSSH2` trait on iOS must ship one (for example [Mozilla's bundle](https://curl.se/docs/caextract.html)) and register it before the first HTTPS operation:

```swift
SwiftGit2Init()
SwiftGit2SetSSLCertificateLocations(file: Bundle.main.url(forResource: "cacert", withExtension: "pem"), directory: nil)
```

## Developing SwiftGit2

If you want to build and test SwiftGit2 locally for development purposes:

1. Clone SwiftGit2
2. Run `git submodule update --init` to clone the libgit2 submodule
3. Run `swift test` or open the `Package.swift` file to develop and test using Xcode

## Contributions

We :heart: to receive pull requests! GitHub makes it easy:

1. Fork the repository
2. Create a branch with your changes
3. Send a Pull Request

All contributions should match GitHub’s [Swift Style Guide](https://github.com/github/swift-style-guide).

## License

SwiftGit2 is available under the [MIT license](https://github.com/SwiftGit2/SwiftGit2/blob/master/LICENSE.md).
