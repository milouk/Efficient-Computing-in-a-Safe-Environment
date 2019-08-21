/*
 * VIA: https://gist.github.com/teknoraver/ebee75c5bc4eb8533b8e761d0e57b7d9
 * ctx_time Copyright (C) 2018 Matteo Croce <mcroce@redhat.com>
 * a tool measure the context switch time in clock cycles
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include <x86intrin.h>

int main (int argc, char *argv[])
{
	int i;
	unsigned long long min = ULLONG_MAX;
	unsigned long long time;
	unsigned junk;


	for (i = 0; i < 100000000; i++) {
		time = __rdtscp(&junk);
		/* Can't be used with BSD because raises a SIGSYS which
		 * consumes ~200 extra clock cycles even if trapped.
		 * Replace with:
		 * getuid();
		 */
		syscall(-1L);
		time = __rdtscp(&junk) - time;

		if (time < min)
			min = time;
	}
	printf("ctx: %llu clocks\n", min);

	return 0;
}
