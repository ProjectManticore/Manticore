#pragma once
#include <stdint.h>

#define kCFCoreFoundationVersionNumber_iOS_14_0 1740.00

extern pthread_t* redeem_racers;

uint64_t cicuta_virosa(void);

uint64_t read_64(uint64_t addr);

uint32_t read_32(uint64_t addr);

void write_20(uint64_t addr, const void* buf);

void write_32(uint64_t addr, const void* buf);

void write_64(uint64_t addr, const void* buf);
