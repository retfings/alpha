/// HTTP Server C Implementation
///
/// POSIX socket-based HTTP server for MoonBit

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>

#define BUFFER_SIZE 65536
#define MAX_CONNECTIONS 10

// Global server socket file descriptor
static int g_server_fd = -1;

/// Create HTTP server socket
/// Returns server_fd on success, -1 on failure
int moonbit_http_server_create(int port) {
    int server_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    // Create socket
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket failed");
        return -1;
    }

    // Set socket options
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        close(server_fd);
        return -1;
    }

    // Bind socket
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        close(server_fd);
        return -1;
    }

    // Start listening
    if (listen(server_fd, MAX_CONNECTIONS) < 0) {
        perror("listen failed");
        close(server_fd);
        return -1;
    }

    g_server_fd = server_fd;
    return server_fd;
}

/// Accept incoming connection and read request
/// Returns request string (caller must free), or empty string on error
char* moonbit_http_server_accept(int server_fd) {
    int client_fd;
    struct sockaddr_in address;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE] = {0};

    // Accept connection (non-blocking in production)
    client_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
    if (client_fd < 0) {
        perror("accept failed");
        return strdup("");
    }

    // Read HTTP request
    ssize_t bytes_read = read(client_fd, buffer, BUFFER_SIZE - 1);
    if (bytes_read < 0) {
        perror("read failed");
        close(client_fd);
        return strdup("");
    }

    buffer[bytes_read] = '\0';

    // Close client connection (keep-alive would be handled differently in production)
    close(client_fd);

    return strdup(buffer);
}

/// Send HTTP response to client
/// Returns 0 on success, -1 on error
int moonbit_http_server_respond(int server_fd, const char* response) {
    int client_fd;
    struct sockaddr_in address;
    int addrlen = sizeof(address);

    // Accept connection
    client_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
    if (client_fd < 0) {
        perror("accept for respond failed");
        return -1;
    }

    // Build HTTP response headers
    char http_response[BUFFER_SIZE];
    int body_len = strlen(response);
    int header_len = snprintf(http_response, sizeof(http_response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "\r\n", body_len);

    // Send headers
    if (send(client_fd, http_response, header_len, 0) < 0) {
        perror("send headers failed");
        close(client_fd);
        return -1;
    }

    // Send body
    if (send(client_fd, response, body_len, 0) < 0) {
        perror("send body failed");
        close(client_fd);
        return -1;
    }

    close(client_fd);
    return 0;
}

/// Close server socket
/// Returns 0 on success, -1 on error
int moonbit_http_server_close(int server_fd) {
    if (server_fd >= 0) {
        close(server_fd);
        g_server_fd = -1;
        return 0;
    }
    return -1;
}
