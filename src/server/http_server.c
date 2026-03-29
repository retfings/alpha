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

#define BUFFER_SIZE 2097152  // 2MB - to support large screener responses with 5000+ stocks
#define MAX_CONNECTIONS 10

static int g_server_fd = -1;
static int g_client_fd = -1;

int moonbit_http_server_create(int port) {
    int server_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket failed");
        return -1;
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        close(server_fd);
        return -1;
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        close(server_fd);
        return -1;
    }

    if (listen(server_fd, MAX_CONNECTIONS) < 0) {
        perror("listen failed");
        close(server_fd);
        return -1;
    }

    g_server_fd = server_fd;
    return server_fd;
}

#include "moonbit.h"

char* moonbit_http_server_accept(int server_fd) {
    struct sockaddr_in address;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE] = {0};

    g_client_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
    if (g_client_fd < 0) {
        perror("accept failed");
        return strdup("");
    }

    ssize_t bytes_read = recv(g_client_fd, buffer, BUFFER_SIZE - 1, 0);
    if (bytes_read < 0) {
        perror("recv failed");
        close(g_client_fd);
        g_client_fd = -1;
        return strdup("");
    }

    buffer[bytes_read] = '\0';

    // Create MoonBit Bytes object with correct length
    moonbit_bytes_t result = moonbit_make_bytes(bytes_read, 0);
    memcpy(result, buffer, bytes_read);

    // Return as char* (MoonBit will interpret it correctly)
    return (char*)result;
}

int moonbit_http_server_respond(int server_fd, int status_code, const unsigned char* body, const char* content_type) {
    if (g_client_fd < 0) {
        perror("no client connection");
        return -1;
    }

    // Bytes from MoonBit is already UTF-8 encoded, just need to get length
    // MoonBit Bytes has length stored in the object header
    int body_len = 0;
    const unsigned char* p = body;
    while (*p++ != 0 && body_len < BUFFER_SIZE) {
        body_len++;
    }

    char http_response[BUFFER_SIZE];
    int header_len = snprintf(http_response, sizeof(http_response),
        "HTTP/1.1 %d OK\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "\r\n", status_code, content_type ? content_type : "application/json", body_len);

    if (send(g_client_fd, http_response, header_len, 0) < 0) {
        perror("send headers failed");
        close(g_client_fd);
        g_client_fd = -1;
        return -1;
    }

    if (send(g_client_fd, body, body_len, 0) < 0) {
        perror("send body failed");
        close(g_client_fd);
        g_client_fd = -1;
        return -1;
    }

    close(g_client_fd);
    g_client_fd = -1;
    return 0;
}

int moonbit_http_server_close(int server_fd) {
    if (server_fd >= 0) {
        close(server_fd);
        g_server_fd = -1;
        return 0;
    }
    return -1;
}
