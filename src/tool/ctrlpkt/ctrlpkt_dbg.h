/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef CTRLPKT_DBG_H
#define CTRLPKT_DBG_H

#include <stdint.h>
#include <stdio.h>

typedef struct {
    uint32_t at;
    const char *text;
} cpd_mark;

typedef void (*cpd_note_fn)(void *ctx, uint32_t acc, uint32_t at, const uint32_t *words, uint32_t len, char *buf,
                            size_t n);

FILE *cpd_open_h(const char *dir, const char *name, const char *title);
void cpd_array(FILE *f, FILE *ann, const char *name, const uint32_t *w, uint32_t n, const cpd_mark *marks, int nmarks,
               cpd_note_fn note, void *ctx);
int cpd_close_h(FILE *f);
FILE *cpd_open_raw(const char *dir, const char *file, const char *mode);
int cpd_bin(const char *dir, const char *name, const uint32_t *w, uint32_t n);
int cpd_dump(const char *dir, const char *name, const char *title, const uint32_t *w, uint32_t n,
             const cpd_mark *marks, int nmarks, cpd_note_fn note, void *ctx);

typedef struct {
    cpd_mark *marks;
    int nmarks;
    char **notes;
    uint32_t nnotes;
} cpd_ann;
int cpd_ann_load(const char *dir, const char *name, uint32_t shift, cpd_ann *a);
void cpd_ann_free(cpd_ann *a);

void cpd_index(const char *dir, const char *name, uint32_t words, const char *what);

#endif
