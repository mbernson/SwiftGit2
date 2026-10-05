#ifndef CLIBGIT2_SHIMS_H
#define CLIBGIT2_SHIMS_H

// The `git_libgit2_opts` function from libgit2 is not callable from Swift because it uses variadic arguments.
// Therefore we expose these methods, so libgit2 options may be configured from Swift.

/// Set the SSL certificate-authority locations.
///
/// - `file` is the location of a file containing several certificates concatenated together.
/// - `path` is the location of a directory holding several certificates, one per file.
///
/// Calling `GIT_OPT_ADD_SSL_X509_CERT` may override the data in path.
///
/// Either parameter may be `NULL`, but not both.
///
/// Wraps `git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, file, path)`.
int swiftgit2_set_ssl_cert_locations(const char *_Nullable file, const char *_Nullable path);

#endif
