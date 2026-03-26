// C stub for file I/O operations
// Used by MoonBit FFI for CSV loading and report saving

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <moonbit.h>

#ifdef _WIN32
#include <direct.h>
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
