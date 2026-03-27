// C stub for file I/O operations
// Used by MoonBit FFI for CSV loading and report saving

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <moonbit.h>

#ifdef _WIN32
#include <direct.h>
#else
#include <dirent.h>
#include <unistd.h>
#endif

// Read file content and return as Bytes
MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f) {
    return NULL;
  }

  // Get file size
  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  fseek(f, 0, SEEK_SET);

  if (size < 0) {
    fclose(f);
    return NULL;
  }

  // Allocate MoonBit Bytes
  moonbit_bytes_t bytes = moonbit_make_bytes(size, 0);

  // Read file content
  size_t read_size = fread(bytes, 1, size, f);
  fclose(f);

  if (read_size != (size_t)size) {
    return NULL;
  }

  return bytes;
}

// Write content to file
MOONBIT_FFI_EXPORT
int32_t moonbit_write_file(const char *path, const char *content, int32_t len) {
  FILE *f = fopen(path, "w");
  if (!f) {
    return -1;
  }

  size_t written = fwrite(content, 1, len, f);
  fclose(f);

  return (written == (size_t)len) ? 0 : -1;
}

// Check if file exists
MOONBIT_FFI_EXPORT
int32_t moonbit_file_exists(const char *path) {
  struct stat st;
  return (stat(path, &st) == 0) ? 1 : 0;
}

// Create directory (including parent directories)
MOONBIT_FFI_EXPORT
int32_t moonbit_mkdir_p(const char *path) {
  char tmp[1024];
  char *p = NULL;
  size_t len;

  snprintf(tmp, sizeof(tmp), "%s", path);
  len = strlen(tmp);

  // Remove trailing slash
  if (tmp[len - 1] == '/') {
    tmp[len - 1] = 0;
  }

  // Create each directory component
  for (p = tmp + 1; *p; p++) {
    if (*p == '/') {
      *p = 0;
#ifdef _WIN32
      _mkdir(tmp);
#else
      mkdir(tmp, 0755);
#endif
      *p = '/';
    }
  }

  // Create final directory
#ifdef _WIN32
  _mkdir(tmp);
#else
  mkdir(tmp, 0755);
#endif

  return 0;
}

// Get environment variable value
MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_getenv(const char *name) {
  const char *value = getenv(name);
  if (value == NULL) {
    return NULL;
  }

  size_t len = strlen(value);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, value, len);
  return bytes;
}

// Delete file
MOONBIT_FFI_EXPORT
int32_t moonbit_remove_file(const char *path) {
  return remove(path) == 0 ? 0 : -1;
}

// Get file size
MOONBIT_FFI_EXPORT
int64_t moonbit_get_file_size(const char *path) {
  struct stat st;
  if (stat(path, &st) != 0) {
    return -1;
  }
  return (int64_t)st.st_size;
}

// Get file modified time (Unix timestamp)
MOONBIT_FFI_EXPORT
int64_t moonbit_get_file_mtime(const char *path) {
  struct stat st;
  if (stat(path, &st) != 0) {
    return -1;
  }
  return (int64_t)st.st_mtime;
}

// Get current working directory
MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_getcwd() {
  char buf[4096];
  if (getcwd(buf, sizeof(buf)) == NULL) {
    return NULL;
  }
  size_t len = strlen(buf);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, buf, len);
  return bytes;
}

// Get project root directory (find moon.mod.json)
MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_get_project_root() {
  char cwd[4096];
  if (getcwd(cwd, sizeof(cwd)) == NULL) {
    return NULL;
  }

  char path[4096];
  strncpy(path, cwd, sizeof(path) - 1);
  path[sizeof(path) - 1] = '\0';

  // Try current directory first
  char check_path[4100];
  snprintf(check_path, sizeof(check_path), "%s/moon.mod.json", path);
  FILE *f = fopen(check_path, "r");
  if (f) {
    fclose(f);
    moonbit_bytes_t bytes = moonbit_make_bytes(strlen(path), 0);
    memcpy(bytes, path, strlen(path));
    return bytes;
  }

  // Walk up directory tree
  char *last_slash = strrchr(path, '/');
  while (last_slash != NULL) {
    *last_slash = '\0';
    snprintf(check_path, sizeof(check_path), "%s/moon.mod.json", path);
    f = fopen(check_path, "r");
    if (f) {
      fclose(f);
      size_t len = strlen(path);
      moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
      memcpy(bytes, path, len);
      return bytes;
    }
    last_slash = strrchr(path, '/');
  }

  // Not found, return current directory
  moonbit_bytes_t bytes = moonbit_make_bytes(strlen(cwd), 0);
  memcpy(bytes, cwd, strlen(cwd));
  return bytes;
}

// List files in directory (returns array of file names)
// The result_struct is a pointer to an array of char* that will be allocated
// The caller is responsible for freeing the returned array
MOONBIT_FFI_EXPORT
int32_t moonbit_list_files(const char *dir_path, const char ***result_arr, const char ***result_lens) {
#ifdef _WIN32
  // Windows implementation
  WIN32_FIND_DATAA find_data;
  HANDLE hFind;
  char search_path[MAX_PATH];

  snprintf(search_path, sizeof(search_path), "%s\\*", dir_path);
  hFind = FindFirstFileA(search_path, &find_data);

  if (hFind == INVALID_HANDLE_VALUE) {
    *result_arr = NULL;
    return 0;
  }

  // Count files first
  int count = 0;
  do {
    if (strcmp(find_data.cFileName, ".") != 0 && strcmp(find_data.cFileName, "..") != 0) {
      count++;
    }
  } while (FindNextFileA(hFind, &find_data) != 0);

  FindClose(hFind);

  if (count == 0) {
    *result_arr = NULL;
    return 0;
  }

  // Allocate array
  char **files = (char **)malloc(count * sizeof(char *));
  int *lens = (int *)malloc(count * sizeof(int));

  // Re-scan directory
  hFind = FindFirstFileA(search_path, &find_data);
  int idx = 0;
  do {
    if (strcmp(find_data.cFileName, ".") != 0 && strcmp(find_data.cFileName, "..") != 0) {
      size_t len = strlen(find_data.cFileName);
      files[idx] = (char *)malloc(len + 1);
      strcpy(files[idx], find_data.cFileName);
      lens[idx] = (int)len;
      idx++;
    }
  } while (FindNextFileA(hFind, &find_data) != 0);

  FindClose(hFind);
  *result_arr = (const char **)files;
  *result_lens = (const char **)lens;
  return count;
#else
  // POSIX implementation
  DIR *dir = opendir(dir_path);
  if (!dir) {
    *result_arr = NULL;
    return 0;
  }

  // Count files first
  struct dirent *entry;
  int count = 0;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
      count++;
    }
  }

  rewinddir(dir);

  if (count == 0) {
    closedir(dir);
    *result_arr = NULL;
    return 0;
  }

  // Allocate array
  char **files = (char **)malloc(count * sizeof(char *));
  int *lens = (int *)malloc(count * sizeof(int));

  // Read directory entries
  int idx = 0;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
      size_t len = strlen(entry->d_name);
      files[idx] = (char *)malloc(len + 1);
      strcpy(files[idx], entry->d_name);
      lens[idx] = (int)len;
      idx++;
    }
  }

  closedir(dir);
  *result_arr = (const char **)files;
  *result_lens = (const char **)lens;
  return count;
#endif
}
