#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <syslog.h>
#include <errno.h>

#define MAX_STRING_LENGTH 256 


int main(int argc, char *agrv[]) {

	if (argc != 3) {
		fprintf(stderr, "Usage: %s <write_file_path> <string>", agrv[0]);
	}

	const char *file_path = agrv[1];
	const char *string_to_write = agrv[2];

	openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

	syslog(LOG_DEBUG, "Writing \"%s\" to \"%s\"", string_to_write, file_path);
	
	FILE *file = fopen(file_path, "w");

	if (file == NULL) {

		syslog(LOG_ERR, file_path, strerror(errno));
		closelog();
		exit(EXIT_FAILURE);
	}

	if (fputs(string_to_write, file) == EOF) {

		syslog(LOG_ERR, "Error writing to file \"%s\": %s", file_path, strerror(errno));
		fclose(file);
		closelog();
		closelog();
		exit(EXIT_FAILURE);
	}

	fclose(file);
	syslog(LOG_DEBUG, "Successfullly wrote \"%s\" to \"%s\"", string_to_write, file_path);
	closelog();

	return 0;
}
