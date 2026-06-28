#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif
#include "scheme.h"

static void custom_init(void) {}

int main(int argc, char *argv[]) {
  /* Resolve binary location */
  char bin[1024];
  ssize_t len = -1;
#ifdef __APPLE__
  uint32_t size = sizeof(bin);
  if (_NSGetExecutablePath(bin, &size) == 0)
    len = strlen(bin);
#else
  len = readlink("/proc/self/exe", bin, sizeof(bin) - 1);
#endif
  if (len == -1) {
    strncpy(bin, argv[0], sizeof(bin) - 1);
    len = strlen(bin);
  }
  bin[len] = '\0';
  char *bin_dir = dirname(bin);

  /* Resolve project root */
  char root[1024];
  snprintf(root, sizeof(root), "%s/..", bin_dir);
  chdir(root);
  setenv("VENUS_ROOT", root, 1);

  /* Find boot files: try project lib/chez first, then CHEZ_DIR, then scheme in PATH */
  char boot_dir[2048];
  int found = 0;

  /* 1. Check lib/chez/ relative to project root */
  snprintf(boot_dir, sizeof(boot_dir), "%s/lib/chez", root);
  char test_path[2048];
  snprintf(test_path, sizeof(test_path), "%s/petite.boot", boot_dir);
  if (access(test_path, R_OK) == 0) {
    found = 1;
  }

  /* 2. Check CHEZ_DIR env */
  if (!found) {
    const char *chez_dir = getenv("CHEZ_DIR");
    if (chez_dir) {
      snprintf(boot_dir, sizeof(boot_dir), "%s/lib/csv10.4.1/tarm64osx", chez_dir);
      snprintf(test_path, sizeof(test_path), "%s/petite.boot", boot_dir);
      if (access(test_path, R_OK) == 0) {
        found = 1;
      }
    }
  }

  if (!found) {
    fprintf(stderr, "Error: cannot find Chez Scheme boot files\n");
    fprintf(stderr, "Ensure lib/chez/ has boot files, or set CHEZ_DIR\n");
    return 1;
  }

  Sscheme_init(NULL);

  char petite_boot[2048], scheme_boot[2048];
  snprintf(petite_boot, sizeof(petite_boot), "%s/petite.boot", boot_dir);
  snprintf(scheme_boot, sizeof(scheme_boot), "%s/scheme.boot", boot_dir);
  Sregister_boot_file(petite_boot);
  Sregister_boot_file(scheme_boot);

  Sbuild_heap(argv[0], custom_init);

  /* Build path to chez_main.ss */
  char script[2048];
  snprintf(script, sizeof(script), "%s/src/chez_main.ss", root);

  int ret = Sscheme_script(script, argc, (const char **)argv);

  Sscheme_deinit();
  return ret;
}
