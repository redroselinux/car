#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char **split_string_by_lines(const char *str, int *line_count) {
    int count = 1; // At least one line
    const char *p = str;

    // Count the number of lines
    while (*p) {
        if (*p == '\n') count++;
        p++;
    }

    char **lines = malloc(count * sizeof(char *));
    if (!lines) return NULL;

    p = str;
    int i = 0;
    const char *start = p;

    // Split the string into lines
    while (*p) {
        if (*p == '\n') {
            int len = p - start;
            lines[i] = malloc(len + 1);
            if (!lines[i]) {
                // Free previously allocated lines
                for (int j = 0; j < i; j++) free(lines[j]);
                free(lines);
                return NULL;
            }
            strncpy(lines[i], start, len);
            lines[i][len] = '\0';
            i++;
            start = p + 1;
        }
        p++;
    }

    // Add the last line
    int len = p - start;
    lines[i] = malloc(len + 1);
    if (!lines[i]) {
        for (int j = 0; j < i; j++) free(lines[j]);
        free(lines);
        return NULL;
    }
    strncpy(lines[i], start, len);
    lines[i][len] = '\0';

    *line_count = count;
    return lines;
}
