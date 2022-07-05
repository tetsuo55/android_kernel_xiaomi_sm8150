# SPDX-License-Identifier: GPL-2.0-only
zram-y	:=	zcomp.o zram_drv.o
zram-$(CONFIG_ZRAM_DEDUP)	+=	zram_dedup.o

ifeq ($(CONFIG_ANDROID),y)
CFLAGS_zram_drv.o += -DCONFIG_ZRAM_MEMORY_TRACKING
endif

obj-$(CONFIG_ZRAM)	+=	zram.o
