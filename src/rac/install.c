#include <stdio.h>
#include <string.h>
#include <time.h>

#include "../tui.c"
#include "../misc/split_lines.c"
#include "../misc/trim.c"

int install(char *package, char* alias) {
    char default_alias[32];
    if (alias == NULL) {
        alias = default_alias;
        snprintf(alias, sizeof(default_alias), "%s", package);
    }

    FILE *repro = fopen("/etc/repro.car", "r");
    if (repro == NULL) {
        log_error("car not initialized");
    }

    fseek(repro, 0, SEEK_END);
    long file_size = ftell(repro);
    fseek(repro, 0, SEEK_SET);

    char *text = malloc(file_size + 1);
    if (!text) {
    fclose(repro);
    return -1;
    }

    fread(text, 1, file_size, repro);
    text[file_size] = '\0';
    fclose(repro);

    int line_count;
    int found;
    char **lines = split_string_by_lines(text, &line_count);
    free(text);

    for (int i = 0; i < line_count; i++) {
    char *eq_pos = strchr(lines[i], '=');
    if (eq_pos) {
        *eq_pos = '\0'; // split the string at '='
        if (strcmp(lines[i], package) == 0) {
            log_warning("package already installed. reinstalling");
            found = 1;
            break;
        }
    }
    }

    for (int i = 0; i < line_count; i++) {
    free(lines[i]);
    }
    free(lines);

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    char unpack_command[100];

    system("mkdir -p /tmp/car");
    snprintf(
        unpack_command,
        sizeof(unpack_command),
        "tar --zstd --directory=/tmp/car --strip-components=1 -xf %s",
    package
    );

    if (system(unpack_command) != 0) {
    log_error("failed to unpack package");
    return 1;
    }

    FILE *script = fopen("/tmp/car/car", "r");
    if (script == NULL) {
    log_error("package does not contain manifest");
    return 127;
    }
    fseek(script, 0, SEEK_END);
    long script_size = ftell(script);
    fseek(script, 0, SEEK_SET);

    char *script_text = malloc(script_size + 1);
    fread(script_text, 1, script_size, script);
    script_text[script_size] = '\0';
    fclose(script);

    int script_line_count;
    char **script_lines = split_string_by_lines(script_text, &script_line_count);
    free(script_text);

    char version[64] = "unknown";

    for (int i = 0; i < script_line_count; i++) {
    char *space = strchr(script_lines[i], ' ');
    if (!space) continue;

    *space = '\0';
    char *value = trim(space + 1);

    if (strcmp(script_lines[i], "version") == 0) {
        snprintf(version, sizeof(version), "%s", value);
    }
    }

    for (int i = 0; i < script_line_count; i++) free(script_lines[i]);
    free(script_lines);

    system("cp -a /tmp/car/. /"); 
    remove("/car");

    FILE* h_config = fopen("/etc/repro.car", "a");
    if (h_config == NULL) {
        log_error("i think you just deleted repro.car while i was installing HEYY");
        return -69;
    }

    if (h_config != NULL && alias != NULL) {
        fseek(h_config, 0, SEEK_END);
        fprintf(h_config, "%s=%s\n", alias, version);
        fflush(h_config);
    }

    fclose(h_config);

    clock_gettime(CLOCK_MONOTONIC, &end);

    double elapsed =
    (end.tv_sec - start.tv_sec) +
    (end.tv_nsec - start.tv_nsec) / 1e9;

    char msg[150];

    if (elapsed >= 1.0) {
      snprintf(msg, sizeof(msg), "installed %s (%s) in %.2f seconds", alias, version, elapsed);
    } else {
      snprintf(msg, sizeof(msg), "installed %s (%s) in %.0f ms", alias, version, elapsed * 1000);
    }

    log_ok(msg);
    return 0;
}

