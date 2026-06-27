#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int run_lua_file(lua_State *L, const char *path) {
  if (luaL_loadfile(L, path) || lua_pcall(L, 0, 0, 0)) {
    fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
    return 1;
  }
  return 0;
}

static int run_venus_main(lua_State *L, const char *root) {
  /* Set up package.path so require("src.*") resolves against root */
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  size_t old_len;
  const char *old_path = lua_tolstring(L, -1, &old_len);
  char *new_path = malloc(old_len + strlen(root) + 32);
  sprintf(new_path, "%s/src/?.lua;%s", root, old_path);
  lua_pushstring(L, new_path);
  lua_setfield(L, -3, "path");
  free(new_path);
  lua_pop(L, 2);

  /* Set VENUS_ROOT so Lua code can find project files if needed */
  lua_pushstring(L, root);
  lua_setglobal(L, "VENUS_ROOT");

  /* Load and run main.lua */
  char main_path[1024];
  snprintf(main_path, sizeof(main_path), "%s/src/main.lua", root);
  return run_lua_file(L, main_path);
}

int main(int argc, char *argv[]) {
  lua_State *L = luaL_newstate();
  if (!L) {
    fprintf(stderr, "Error: could not create Lua state\n");
    return 1;
  }
  luaL_openlibs(L);

  /* Resolve project root from binary path */
  char bin[1024];
  strncpy(bin, argv[0], sizeof(bin) - 1);
  bin[sizeof(bin) - 1] = '\0';
  char *bin_dir = dirname(bin);
  char root[1024];
  snprintf(root, sizeof(root), "%s/..", bin_dir);

  /* Set up arg table */
  lua_createtable(L, argc - 1, 0);
  for (int i = 1; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "arg");

  int ret = run_venus_main(L, root);
  lua_close(L);
  return ret;
}
