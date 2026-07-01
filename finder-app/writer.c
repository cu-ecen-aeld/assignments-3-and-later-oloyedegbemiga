#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char*argv[]){
    FILE *fp;
    const char *writefile;
    const char *writestr;

    openlog("writer", LOG_PID, LOG_USER);

    if (argc != 3){

        syslog(LOG_ERR, "Invalid number of arguments: %d", argc -1);
        closelog();
        return 1;
    }

    writefile = argv[1];
    writestr = argv[2];

    syslog(LOG_DEBUG, "writing %s to %s", writestr, writefile);
    fp = fopen(writefile, "w");
    if (fp == NULL){
        syslog(LOG_ERR, "Could not open file %s for writing", writefile);
        closelog();
        return 1;
    }

    int ret = fprintf(fp, "%s\n", writestr);

    if (ret < 0){
        syslog(LOG_ERR, "could not write to fle %s", writefile);
    }

    fclose(fp);
    closelog();
    return 0;
}