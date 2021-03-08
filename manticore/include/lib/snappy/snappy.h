/* Copyright 2018 Sam Bingner All Rights Reserved
	 */

#ifndef _SNAPPY_H
#define _SNAPPY_H

#ifdef __cplusplus
extern "C" {
#endif

const char **snapshot_list(int dirfd);
bool snapshot_check(int dirfd, const char *name);
char *copySystemSnapshot(void);

#ifdef __cplusplus
}
#endif

#endif
