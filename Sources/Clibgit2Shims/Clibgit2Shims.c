#include "Clibgit2Shims.h"
#include <git2.h>

int swiftgit2_set_ssl_cert_locations(const char *file, const char *path) {
	return git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, file, path);
}
