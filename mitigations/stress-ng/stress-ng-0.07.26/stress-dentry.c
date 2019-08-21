/*
 * Copyright (C) 2013-2017 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * This code is a complete clean re-write of the stress tool by
 * Colin Ian King <colin.king@canonical.com> and attempts to be
 * backwardly compatible with the stress tool by Amos Waterland
 * <apw@rossby.metr.ou.edu> but has more stress tests and more
 * functionality.
 *
 */
#include "stress-ng.h"

typedef enum {
	ORDER_FORWARD,
	ORDER_REVERSE,
	ORDER_STRIDE,
	ORDER_RANDOM,
	ORDER_NONE,
} dentry_order_t;

typedef struct {
	const char *name;
	const dentry_order_t order;
} dentry_removal_t;

static const dentry_removal_t dentry_removals[] = {
	{ "forward",	ORDER_FORWARD },
	{ "reverse",	ORDER_REVERSE },
	{ "stride",	ORDER_STRIDE },
	{ "random",	ORDER_RANDOM },
	{ NULL,		ORDER_NONE },
};

static dentry_order_t order = ORDER_RANDOM;
static uint64_t opt_dentries = DEFAULT_DENTRIES;
static bool set_dentries = false;

void stress_set_dentries(const char *optarg)
{
	set_dentries = true;
	opt_dentries = get_uint64(optarg);
	check_range("dentries", opt_dentries,
		MIN_DENTRIES, MAX_DENTRIES);
}

/*
 *  stress_set_dentry_order()
 *	set dentry ordering from give option
 */
int stress_set_dentry_order(const char *optarg)
{
	const dentry_removal_t *dr;

	for (dr = dentry_removals; dr->name; dr++) {
		if (!strcmp(dr->name, optarg)) {
			order = dr->order;
			return 0;
		}
	}

	(void)fprintf(stderr, "dentry-order must be one of:");
	for (dr = dentry_removals; dr->name; dr++) {
		(void)fprintf(stderr, " %s", dr->name);
	}
	(void)fprintf(stderr, "\n");

	return -1;
}

/*
 *  stress_dentry_unlink()
 *	remove all dentries
 */
static void stress_dentry_unlink(
	const args_t *args,
	const uint64_t n)
{
	uint64_t i, j;
	uint64_t prime;
	dentry_order_t ord;

	ord = (order == ORDER_RANDOM) ?
		mwc32() % 3 : order;

	switch (ord) {
	case ORDER_REVERSE:
		for (i = 0; i < n; i++) {
			char path[PATH_MAX];
			uint64_t gray_code;

			j = (n - 1) - i;
			gray_code = (j >> 1) ^ j;

			stress_temp_filename_args(args,
				path, sizeof(path), gray_code);
			(void)unlink(path);
		}
		break;
	case ORDER_STRIDE:
		prime = stress_get_prime64(n);
		for (i = 0, j = prime; i < n; i++, j += prime) {
			char path[PATH_MAX];
			uint64_t k = j % n;
			uint64_t gray_code = (k >> 1) ^ k;

			stress_temp_filename_args(args,
				path, sizeof(path), gray_code);
			(void)unlink(path);
		}
		break;
	case ORDER_FORWARD:
	default:
		for (i = 0; i < n; i++) {
			char path[PATH_MAX];
			uint64_t gray_code = (i >> 1) ^ i;

			stress_temp_filename_args(args,
				path, sizeof(path), gray_code);
			(void)unlink(path);
		}
		break;
	}
	sync();
}

/*
 *  stress_dentry
 *	stress dentries
 */
int stress_dentry(const args_t *args)
{
	int ret;

	if (!set_dentries) {
		if (g_opt_flags & OPT_FLAGS_MAXIMIZE)
			opt_dentries = MAX_DENTRIES;
		if (g_opt_flags & OPT_FLAGS_MINIMIZE)
			opt_dentries = MIN_DENTRIES;
	}

	ret = stress_temp_dir_mk_args(args);
	if (ret < 0)
		return exit_status(-ret);

	do {
		uint64_t i, n = opt_dentries;

		for (i = 0; i < n; i++) {
			char path[PATH_MAX];
			uint64_t gray_code = (i >> 1) ^ i;
			int fd;

			stress_temp_filename_args(args,
				path, sizeof(path), gray_code);

			if ((fd = open(path, O_CREAT | O_RDWR,
					S_IRUSR | S_IWUSR)) < 0) {
				if (errno != ENOSPC)
					pr_fail_err("open");
				n = i;
				break;
			}
			(void)close(fd);

			if (!keep_stressing())
				goto abort;

			inc_counter(args);
		}
		stress_dentry_unlink(args, n);
		if (!g_keep_stressing_flag)
			break;
		sync();
	} while (keep_stressing());

abort:
	/* force unlink of all files */
	pr_tidy("%s: removing %" PRIu64 " entries\n",
		args->name, opt_dentries);
	stress_dentry_unlink(args, opt_dentries);
	(void)stress_temp_dir_rm_args(args);

	return EXIT_SUCCESS;
}
