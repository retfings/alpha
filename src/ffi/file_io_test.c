// Standalone unit tests for file I/O operations
// Compile with: gcc -o file_io_test file_io_test.c -lm && ./file_io_test
// This test file includes standalone implementations for testing

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef _WIN32
#include <direct.h>
#define mkdir(p, m) _mkdir(p)
#endif

// Mock MoonBit types and functions for standalone testing
typedef char* moonbit_bytes_t;

#define moonbit_make_bytes(size, init) ((moonbit_bytes_t)calloc(size + 1, 1))
#define moonbit_bytes_length(b) (strlen(b))

// Copy of the FFI functions for standalone testing
static char* read_file_impl(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size < 0) {
        fclose(f);
        return NULL;
    }

    char *bytes = (char *)malloc(size + 1);
    if (!bytes) {
        fclose(f);
        return NULL;
    }

    size_t read_size = fread(bytes, 1, size, f);
    fclose(f);

    if (read_size != (size_t)size) {
        free(bytes);
        return NULL;
    }

    bytes[size] = '\0';
    return bytes;
}

static int write_file_impl(const char *path, const char *content, int len) {
    FILE *f = fopen(path, "w");
    if (!f) {
        return -1;
    }

    size_t written = fwrite(content, 1, len, f);
    fclose(f);

    return (written == (size_t)len) ? 0 : -1;
}

static int file_exists_impl(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0) ? 1 : 0;
}

static int mkdir_p_impl(const char *path) {
    char tmp[1024];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);

    if (len > 0 && tmp[len - 1] == '/') {
        tmp[len - 1] = 0;
    }

    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0755);
            *p = '/';
        }
    }

    mkdir(tmp, 0755);
    return 0;
}

// Test counters
static int tests_run = 0;
static int tests_passed = 0;
static int tests_failed = 0;

// Test macros
#define TEST(name) static void name(void)
#define RUN_TEST(name) do { \
    printf("Running %s... ", #name); \
    tests_run++; \
    name(); \
    tests_passed++; \
    printf("PASSED\n"); \
} while(0)

#define ASSERT(cond) do { \
    if (!(cond)) { \
        printf("FAILED at %s:%d\n", __FILE__, __LINE__); \
        tests_passed--; \
        tests_failed++; \
        return; \
    } \
} while(0)

#define ASSERT_TRUE(cond) ASSERT(cond)
#define ASSERT_FALSE(cond) ASSERT(!(cond))
#define ASSERT_EQ(a, b) ASSERT((a) == (b))
#define ASSERT_STR_EQ(a, b) ASSERT(strcmp((a), (b)) == 0)
#define ASSERT_NOT_NULL(ptr) ASSERT((ptr) != NULL)
#define ASSERT_NULL(ptr) ASSERT((ptr) == NULL)

// Cleanup helpers
static void cleanup_test_file(const char *path) {
    remove(path);
}

static void cleanup_test_dir(const char *path) {
    rmdir(path);
}

// ============ read_file tests ============

TEST(test_read_file_existing_file) {
    const char *test_path = "test_read_file.tmp";
    const char *test_content = "Hello, World!";

    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fputs(test_content, f);
    fclose(f);

    char *result = read_file_impl(test_path);
    ASSERT_NOT_NULL(result);
    ASSERT_STR_EQ(result, test_content);

    free(result);
    cleanup_test_file(test_path);
}

TEST(test_read_file_nonexistent_file) {
    char *result = read_file_impl("nonexistent_file_12345.tmp");
    ASSERT_NULL(result);
}

TEST(test_read_file_empty_file) {
    const char *test_path = "test_empty_file.tmp";

    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fclose(f);

    char *result = read_file_impl(test_path);
    ASSERT_NOT_NULL(result);
    ASSERT_EQ(strlen(result), 0);

    free(result);
    cleanup_test_file(test_path);
}

TEST(test_read_file_binary_content) {
    const char *test_path = "test_binary_file.tmp";
    unsigned char binary_data[] = {0x41, 0x42, 0x43, 0x44, 0x45}; // "ABCDE"

    FILE *f = fopen(test_path, "wb");
    ASSERT_NOT_NULL(f);
    fwrite(binary_data, 1, sizeof(binary_data), f);
    fclose(f);

    char *result = read_file_impl(test_path);
    ASSERT_NOT_NULL(result);
    ASSERT_EQ(strlen(result), sizeof(binary_data));
    ASSERT_TRUE(memcmp(result, binary_data, sizeof(binary_data)) == 0);

    free(result);
    cleanup_test_file(test_path);
}

TEST(test_read_file_large_content) {
    const char *test_path = "test_large_file.tmp";
    const size_t large_size = 10000;

    char *large_content = (char *)malloc(large_size);
    ASSERT_NOT_NULL(large_content);
    memset(large_content, 'X', large_size - 1);
    large_content[large_size - 1] = '\0';

    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fputs(large_content, f);
    fclose(f);

    char *result = read_file_impl(test_path);
    ASSERT_NOT_NULL(result);
    ASSERT_EQ(strlen(result), large_size - 1);

    free(result);
    free(large_content);
    cleanup_test_file(test_path);
}

// ============ write_file tests ============

TEST(test_write_file_new_file) {
    const char *test_path = "test_write_new.tmp";
    const char *content = "Test content for new file";

    int result = write_file_impl(test_path, content, strlen(content));
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_path, &st), 0);

    cleanup_test_file(test_path);
}

TEST(test_write_file_overwrite) {
    const char *test_path = "test_write_overwrite.tmp";
    const char *original = "Original content";
    const char *new_content = "New content";

    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fputs(original, f);
    fclose(f);

    int result = write_file_impl(test_path, new_content, strlen(new_content));
    ASSERT_EQ(result, 0);

    char *read_back = read_file_impl(test_path);
    ASSERT_NOT_NULL(read_back);
    ASSERT_STR_EQ(read_back, new_content);

    free(read_back);
    cleanup_test_file(test_path);
}

TEST(test_write_file_empty_content) {
    const char *test_path = "test_write_empty.tmp";

    int result = write_file_impl(test_path, "", 0);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_path, &st), 0);
    ASSERT_EQ(st.st_size, 0);

    cleanup_test_file(test_path);
}

TEST(test_write_file_invalid_path) {
    const char *invalid_path = "/invalid/directory/that/does/not/exist/file.txt";
    const char *content = "This should fail";

    int result = write_file_impl(invalid_path, content, strlen(content));
    ASSERT_EQ(result, -1);
}

TEST(test_write_file_special_characters) {
    const char *test_path = "test_special_chars.tmp";
    const char *content = "Special: \n\t\r\"'\\!@#$%^&*()";

    int result = write_file_impl(test_path, content, strlen(content));
    ASSERT_EQ(result, 0);

    char *read_back = read_file_impl(test_path);
    ASSERT_NOT_NULL(read_back);
    ASSERT_STR_EQ(read_back, content);

    free(read_back);
    cleanup_test_file(test_path);
}

// ============ file_exists tests ============

TEST(test_file_exists_existing_file) {
    const char *test_path = "test_exists.tmp";

    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fclose(f);

    int result = file_exists_impl(test_path);
    ASSERT_EQ(result, 1);

    cleanup_test_file(test_path);
}

TEST(test_file_exists_nonexistent_file) {
    int result = file_exists_impl("nonexistent_file_12345.tmp");
    ASSERT_EQ(result, 0);
}

TEST(test_file_exists_directory) {
    const char *test_dir = "test_exists_dir";

    mkdir(test_dir, 0755);

    int result = file_exists_impl(test_dir);
    ASSERT_EQ(result, 1);

    cleanup_test_dir(test_dir);
}

TEST(test_file_exists_after_delete) {
    const char *test_path = "test_exists_delete.tmp";

    // Create file
    FILE *f = fopen(test_path, "w");
    ASSERT_NOT_NULL(f);
    fclose(f);

    // Verify exists
    ASSERT_EQ(file_exists_impl(test_path), 1);

    // Delete
    cleanup_test_file(test_path);

    // Verify not exists
    ASSERT_EQ(file_exists_impl(test_path), 0);
}

// ============ mkdir_p tests ============

TEST(test_mkdir_p_simple_directory) {
    const char *test_dir = "test_simple_dir";

    int result = mkdir_p_impl(test_dir);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_dir, &st), 0);
    ASSERT_TRUE(st.st_mode & S_IFDIR);

    cleanup_test_dir(test_dir);
}

TEST(test_mkdir_p_nested_directories) {
    const char *test_dir = "test_nested/level1/level2/level3";

    int result = mkdir_p_impl(test_dir);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_dir, &st), 0);
    ASSERT_TRUE(st.st_mode & S_IFDIR);

    cleanup_test_dir(test_dir);
    cleanup_test_dir("test_nested/level1/level2");
    cleanup_test_dir("test_nested/level1");
    cleanup_test_dir("test_nested");
}

TEST(test_mkdir_p_existing_directory) {
    const char *test_dir = "test_existing_dir";

    mkdir(test_dir, 0755);

    int result = mkdir_p_impl(test_dir);
    ASSERT_EQ(result, 0);

    cleanup_test_dir(test_dir);
}

TEST(test_mkdir_p_with_trailing_slash) {
    const char *test_dir = "test_trailing_slash/";

    int result = mkdir_p_impl(test_dir);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat("test_trailing_slash", &st), 0);
    ASSERT_TRUE(st.st_mode & S_IFDIR);

    cleanup_test_dir("test_trailing_slash");
}

TEST(test_mkdir_p_single_component) {
    const char *test_dir = "single";

    int result = mkdir_p_impl(test_dir);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_dir, &st), 0);
    ASSERT_TRUE(st.st_mode & S_IFDIR);

    cleanup_test_dir(test_dir);
}

// ============ Integration tests ============

TEST(test_write_then_read_roundtrip) {
    const char *test_path = "test_roundtrip.tmp";
    const char *original_content = "Test content for roundtrip verification";

    int write_result = write_file_impl(test_path, original_content, strlen(original_content));
    ASSERT_EQ(write_result, 0);

    char *read_result = read_file_impl(test_path);
    ASSERT_NOT_NULL(read_result);
    ASSERT_STR_EQ(read_result, original_content);

    free(read_result);
    cleanup_test_file(test_path);
}

TEST(test_mkdir_p_then_write_file) {
    const char *test_dir = "test_write_dir";
    const char *test_file = "test_write_dir/output.txt";
    const char *content = "Content in new directory";

    int mkdir_result = mkdir_p_impl(test_dir);
    ASSERT_EQ(mkdir_result, 0);

    int write_result = write_file_impl(test_file, content, strlen(content));
    ASSERT_EQ(write_result, 0);

    int exists = file_exists_impl(test_file);
    ASSERT_EQ(exists, 1);

    cleanup_test_file(test_file);
    cleanup_test_dir(test_dir);
}

TEST(test_multiple_files_same_directory) {
    const char *test_dir = "test_multi_dir";
    const char *files[] = {"file1.txt", "file2.txt", "file3.txt"};
    const char *contents[] = {"Content 1", "Content 2", "Content 3"};

    mkdir_p_impl(test_dir);

    for (int i = 0; i < 3; i++) {
        char path[256];
        snprintf(path, sizeof(path), "%s/%s", test_dir, files[i]);

        int result = write_file_impl(path, contents[i], strlen(contents[i]));
        ASSERT_EQ(result, 0);
    }

    for (int i = 0; i < 3; i++) {
        char path[256];
        snprintf(path, sizeof(path), "%s/%s", test_dir, files[i]);

        ASSERT_EQ(file_exists_impl(path), 1);
        char *read_back = read_file_impl(path);
        ASSERT_NOT_NULL(read_back);
        ASSERT_STR_EQ(read_back, contents[i]);
        free(read_back);

        cleanup_test_file(path);
    }

    cleanup_test_dir(test_dir);
}

TEST(test_read_write_various_encodings) {
    const char *test_path = "test_encoding.tmp";

    // Test UTF-8 content
    const char *utf8_content = "Hello 世界！🌍 Привет!";

    int write_result = write_file_impl(test_path, utf8_content, strlen(utf8_content));
    ASSERT_EQ(write_result, 0);

    char *read_result = read_file_impl(test_path);
    ASSERT_NOT_NULL(read_result);
    ASSERT_STR_EQ(read_result, utf8_content);

    free(read_result);
    cleanup_test_file(test_path);
}

// ============ Edge case tests ============

TEST(test_write_file_zero_length) {
    const char *test_path = "test_zero.tmp";

    int result = write_file_impl(test_path, "ignored", 0);
    ASSERT_EQ(result, 0);

    struct stat st;
    ASSERT_EQ(stat(test_path, &st), 0);
    ASSERT_EQ(st.st_size, 0);

    cleanup_test_file(test_path);
}

TEST(test_file_exists_empty_string_path) {
    int result = file_exists_impl("");
    ASSERT_EQ(result, 0);
}

TEST(test_mkdir_p_current_directory) {
    // Creating current directory should not fail
    int result = mkdir_p_impl(".");
    ASSERT_EQ(result, 0);
}

// ============ Main test runner ============

int main(void) {
    printf("=== File I/O FFI Unit Tests ===\n\n");

    // read_file tests
    printf("--- read_file tests ---\n");
    RUN_TEST(test_read_file_existing_file);
    RUN_TEST(test_read_file_nonexistent_file);
    RUN_TEST(test_read_file_empty_file);
    RUN_TEST(test_read_file_binary_content);
    RUN_TEST(test_read_file_large_content);
    printf("\n");

    // write_file tests
    printf("--- write_file tests ---\n");
    RUN_TEST(test_write_file_new_file);
    RUN_TEST(test_write_file_overwrite);
    RUN_TEST(test_write_file_empty_content);
    RUN_TEST(test_write_file_invalid_path);
    RUN_TEST(test_write_file_special_characters);
    printf("\n");

    // file_exists tests
    printf("--- file_exists tests ---\n");
    RUN_TEST(test_file_exists_existing_file);
    RUN_TEST(test_file_exists_nonexistent_file);
    RUN_TEST(test_file_exists_directory);
    RUN_TEST(test_file_exists_after_delete);
    printf("\n");

    // mkdir_p tests
    printf("--- mkdir_p tests ---\n");
    RUN_TEST(test_mkdir_p_simple_directory);
    RUN_TEST(test_mkdir_p_nested_directories);
    RUN_TEST(test_mkdir_p_existing_directory);
    RUN_TEST(test_mkdir_p_with_trailing_slash);
    RUN_TEST(test_mkdir_p_single_component);
    printf("\n");

    // Integration tests
    printf("--- Integration tests ---\n");
    RUN_TEST(test_write_then_read_roundtrip);
    RUN_TEST(test_mkdir_p_then_write_file);
    RUN_TEST(test_multiple_files_same_directory);
    RUN_TEST(test_read_write_various_encodings);
    printf("\n");

    // Edge case tests
    printf("--- Edge case tests ---\n");
    RUN_TEST(test_write_file_zero_length);
    RUN_TEST(test_file_exists_empty_string_path);
    RUN_TEST(test_mkdir_p_current_directory);
    printf("\n");

    // Summary
    printf("=== Test Summary ===\n");
    printf("Total tests: %d\n", tests_run);
    printf("Passed: %d\n", tests_passed);
    printf("Failed: %d\n", tests_failed);

    if (tests_failed > 0) {
        printf("\nSome tests FAILED!\n");
        return 1;
    } else {
        printf("\nAll tests PASSED!\n");
        return 0;
    }
}
