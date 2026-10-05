// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftGit2",
    platforms: [
        .macOS(.v10_13),
        .iOS("15.5"),
        .tvOS(.v13),
        .visionOS(.v1),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "SwiftGit2",
            targets: ["SwiftGit2"]
        ),
    ],
    // libgit2 compiles exactly one HTTPS backend and one SSH backend, so the defaults are traits too:
    // enabling OpenSSL or LibSSH2 replaces them rather than adding to them.
    traits: [
        .trait(name: "SecureTransport", description: "HTTPS through Apple's Security framework."),
        .trait(name: "SSHExec", description: "SSH by running the system ssh executable. Not available on iOS."),
        .trait(name: "OpenSSL", description: "HTTPS through precompiled OpenSSL."),
        .trait(name: "LibSSH2", description: "SSH through precompiled libssh2.", enabledTraits: ["OpenSSL"]),
        .default(enabledTraits: ["SecureTransport", "SSHExec"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.5.5"),
        .package(url: "https://github.com/mbernson/OpenSSL-Apple.git", from: "4.0.3"),
        .package(url: "https://github.com/mbernson/libssh2-Apple.git", from: "1.11.1"),
    ],
    targets: [
        .target(
            name: "SwiftGit2",
            dependencies: ["Clibgit2", "Clibgit2Shims"]
        ),
        .testTarget(
            name: "SwiftGit2Tests",
            dependencies: ["SwiftGit2", "Clibgit2", "ZipArchive"],
            resources: [.copy("Fixtures")],
            swiftSettings: [
                .define("OPENSSL", .when(traits: ["OpenSSL"])),
                .define("LIBSSH2", .when(traits: ["LibSSH2"])),
            ]
        ),
        // The `git_libgit2_opts` function from libgit2 is not callable from Swift because it uses variadic arguments.
		// This target with some glue code is needed to be able to use it from Swift.
        .target(
            name: "Clibgit2Shims",
            dependencies: ["Clibgit2"]
        ),
        .target(
            name: "Clibgit2",
            dependencies: [
                .product(name: "OpenSSL", package: "OpenSSL-Apple", condition: .when(traits: ["OpenSSL"])),
                .product(name: "libssh2", package: "libssh2-Apple", condition: .when(traits: ["LibSSH2"])),
            ],
            path: "libgit2",
            exclude: [
                "deps/llhttp/CMakeLists.txt",
                "deps/llhttp/LICENSE-MIT",
                "deps/pcre/CMakeLists.txt",
                "deps/pcre/COPYING",
                "deps/pcre/LICENCE",
                "deps/pcre/cmake",
                "deps/pcre/config.h.in",
                "deps/xdiff/CMakeLists.txt",
                "deps/zlib/CMakeLists.txt",
                "deps/zlib/LICENSE",
                "src/libgit2/CMakeLists.txt",
                "src/libgit2/config.cmake.in",
                "src/libgit2/experimental.h.in",
                "src/libgit2/git2.rc",
                "src/util/CMakeLists.txt",
                "src/util/git2_features.h.in",
                "src/util/hash/builtin.c",
                "src/util/hash/builtin.h",
                "src/util/hash/collisiondetect.c",
                "src/util/hash/collisiondetect.h",
                "src/util/hash/openssl.c",
                "src/util/hash/openssl.h",
                "src/util/hash/win32.c",
                "src/util/hash/win32.h",
                "src/util/win32",
            ],
            sources: [
                "deps/llhttp",
                "deps/pcre",
                "deps/xdiff",
                "deps/zlib",
                "src/libgit2",
                "src/util",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                  // Disable -fmodules flag. Clang finds (`struct entry`) in a different file (`search.h`).
                  "-fno-modules",
                  // Disable warning: "implicit conversion loses integer precision"
                  "-Wno-single-bit-bitfield-constant-conversion", "-Wno-conversion",
                  // Disable warning: "a function definition without a prototype is deprecated"
                  "-Wno-deprecated-non-prototype",
                ]),

                .headerSearchPath("deps/llhttp"),
                .headerSearchPath("deps/pcre"),
                .headerSearchPath("deps/xdiff"),
                .headerSearchPath("deps/zlib"),
                .headerSearchPath("src/libgit2"),
                .headerSearchPath("src/util"),

                .define("LIBGIT2_NO_FEATURES_H"),
                .define("GIT_ARCH_64", to: "1"),
                .define("GIT_THREADS", to: "1"),
                .define("GIT_QSORT_BSD", to: "1"),
                .define("GIT_IO_POLL", to: "1"),
                .define("GIT_USE_FUTIMENS", to: "1"),
                .define("GIT_COMPRESSION_BUILTIN", to: "1"),

                // Nanosecond timestamps in the index, as git itself records them
                .define("GIT_USE_NSEC", to: "1"),
                .define("GIT_USE_STAT_MTIMESPEC", to: "1"),

                // Precomposed Unicode filename handling (core.precomposeunicode)
                .define("GIT_USE_ICONV", to: "1"),

                // Git regex configuration
                .define("GIT_REGEX_BUILTIN", to: "1"),
                .define("PCRE_LINK_SIZE", to: "2"),
                .define("SUPPORT_PCRE8", to: "1"),
                .define("LINK_SIZE", to: "2"),
                .define("PARENS_NEST_LIMIT", to: "250"),
                .define("MATCH_LIMIT", to: "10000000"),
                .define("MATCH_LIMIT_RECURSION", to: "10000000"),
                .define("NEWLINE", to: "10"), // LF
                .define("NO_RECURSE", to: "1"),
                .define("POSIX_MALLOC_THRESHOLD", to: "10"),
                .define("BSR_ANYCRLF", to: "0"),
                .define("MAX_NAME_SIZE", to: "32"),
                .define("MAX_NAME_COUNT", to: "10000"),

                // Git SSH transport configuration
                .define("GIT_SSH", to: "1", .when(traits: ["SSHExec", "LibSSH2"])),
                .define("GIT_SSH_EXEC", to: "1", .when(traits: ["SSHExec"])),
                .define("GIT_SSH_LIBSSH2", to: "1", .when(traits: ["LibSSH2"])),
                .define("GIT_SSH_LIBSSH2_MEMORY_CREDENTIALS", to: "1", .when(traits: ["LibSSH2"])),

                // Git HTTPS transport configuration
                .define("GIT_HTTPS", to: "1"),
                .define("GIT_HTTPPARSER_BUILTIN", to: "1"),
                .define("GIT_SECURE_TRANSPORT", to: "1", .when(traits: ["SecureTransport"])),
                .define("GIT_OPENSSL", to: "1", .when(traits: ["OpenSSL"])),

                // Git cryptography configuration
                .define("GIT_SHA1_COMMON_CRYPTO", to: "1"),
                .define("GIT_SHA256_COMMON_CRYPTO", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("iconv"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
