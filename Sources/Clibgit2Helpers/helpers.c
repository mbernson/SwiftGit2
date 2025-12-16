//
//  helpers.c
//  SwiftGit2
//
//  Created by Mathijs Bernson on 12/12/2025.
//

#include "helpers.h"

#include <git2.h>

int git_opt_set_ssl_cert_locations(const char *file, const char *path) {
    return git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, file, path);
}

int git_opt_set_user_agent(const char *user_agent) {
    return git_libgit2_opts(GIT_OPT_GET_USER_AGENT, user_agent);
}
