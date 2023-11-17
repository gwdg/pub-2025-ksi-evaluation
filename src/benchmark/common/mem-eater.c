#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// Original Author J.K. 2008
// Source: https://github.com/JulianKunkel/io-modelling/blob/master/mem-eater.c
// Edited by Sören Metje 2023
//
// Limits available memory by allocating memory until a certain limit.
// Optional command line parameter:
// - memory limit in MiB (approximate free memory after allocation)


long getValue(char * what){
  char buff[1024];

  int fd = open("/proc/meminfo", O_RDONLY);
  int ret = read(fd, buff, 1023);

  buff[ret>1023 ? 1023: ret] = 0;

  char * line = strstr(buff, what);

	if (line == 0){
		printf("Error %s not found in %s \n", what, buff);
		exit(1);
	}

	line += strlen(what) + 1;


  while(line[0] == ' '){
          line++;
  }

  int pos = 0;
  while(line[pos] != ' '){
          pos++;
  }
  line[pos] = 0;

  close(fd);

  return atoi(line);
}

long getFreeRamKB(){
	return getValue("\nMemFree:") +getValue("\nCached:") + getValue("\nBuffers:");	
}

int preallocate(long long int maxRAMinKB){
	long long int currentRAMinKB = getFreeRamKB();

	printf ("Currently %lld KiB RAM available\nGoal: %lld KiB RAM available\nStarting to malloc RAM...\n", currentRAMinKB, maxRAMinKB);
	
	while(currentRAMinKB > maxRAMinKB){
		long long int delta = currentRAMinKB - maxRAMinKB;
		long long int toMalloc = (delta < 1000 ? delta : 1000) * 1024;

		char * allocP = malloc(toMalloc);
		if(allocP == 0){
			printf("Could not allocate more RAM - retrying - free:%lld \n", currentRAMinKB);
			sleep(5);
		} else {
			memset(allocP, '1', toMalloc);
		}
		currentRAMinKB = getFreeRamKB();
	}

	printf ("Finished. Now %lld KiB RAM is available\n", currentRAMinKB);
}	

int main(int argc, char *argv[]){
  long long int maxRAMinKB = 1024 * 1024; // default 1 GiB

  if (argc >= 2) {
    maxRAMinKB = atoi(argv[1]) * 1024;
  }

	preallocate(maxRAMinKB);
	sleep(36000); // 10 h
}

