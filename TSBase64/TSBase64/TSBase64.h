//
//  TSBase64.h
//  TSBase64
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#ifndef TSBase64_TSBase64_h
#define TSBase64_TSBase64_h


extern size_t base64_encode(const void * from, const size_t from_len, void * to, const size_t to_len);
extern void * base64_encode_alloc(const void * from, const size_t from_len, size_t *to_len);
extern size_t base64_decode(const char * from, const size_t strlen, void * to, const size_t to_len);
extern void * base64_decode_alloc(const void * from, const size_t from_len, size_t *to_len);
extern void base64_free(void * p);

#endif
