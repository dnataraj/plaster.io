//
//  TSBase64.c
//  TSBase64
//
//  Created by Deepak Natarajan on 5/21/13.
//  Copyright (c) 2013 Trilobyte Systems ApS. All rights reserved.
//

#include <stdlib.h>
#include <assert.h>
#include "TSBase64.h"

/*
 RFC 1521
 MIME (Multipurpose Internet Mail Extensions) Part One:
 Mechanisms for Specifying and Describing the Format of Internet Message Bodies
 
 5.2.  Base64 Content-Transfer-Encoding
*/


//returned len includes \0
size_t base64_encode(const void * from, size_t from_len, void * to, const size_t to_len) {
    static const char base64_encoding_map[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    if (NULL == from || 0 == from_len) {
        return 0;
    }
    
    const size_t chunk_len = from_len / 3;
    const size_t aligned_len = chunk_len * 3;
    size_t left = from_len - aligned_len;
    const size_t left_char = left?(left + 1):0;
    const size_t padding = left?(3 - left):0;
    
    const size_t need_len = left_char + chunk_len * 4 + padding + 1 /* \0 null end */ ;
    
    if (NULL == to) {
        return need_len;
    }
    
    if (to_len < need_len) {
        return 0;
    }
    
    unsigned char b1, b2, b3;
    unsigned char c1, c2 ,c3, c4;
    unsigned int m;
    unsigned int bits;
    const unsigned char * p_from = (const unsigned char *)from;
    unsigned char * p_to = (unsigned char *)to;
    size_t i = 0, j = 0;
    
    // use aligned bytes to omit most of conditional statements, means less CMPs & JMPs
    for (; i < aligned_len ;) {
        
        b1 = *(p_from + i);
        b2 = *(p_from + i + 1);
        b3 = *(p_from + i + 2); //slightly faster than the commented, for 14~15MB data, 10ms faster
        //        b1 = *(p_from);p_from ++;
        //        b2 = *(p_from);p_from ++;
        //        b3 = *(p_from);p_from ++;
        i += 3;
        
        // combined a whole 24-bit chunk
        bits = (b1 << 16) | (b2 << 8) | (b3);
        m = (bits & 0xfc0000) >> 18;
        //        m = (b1 & 0xfc) >> 2;
        c1 = base64_encoding_map[m];
        
        m = (bits & 0x3f000) >> 12;
        //        m = ((b1 & 0x3) << 4 ) | ((b2 & 0xf0) >> 4);
        c2 = base64_encoding_map[m];
        
        m = (bits & 0xfc0) >> 6;
        //        m = ((b2 & 0xf) << 2) | ((b3 & 0xc0) >> 6);
        c3 = base64_encoding_map[m];
        
        m = (bits & 0x3f);
        //        m = b3 & 0x3f;
        c4 = base64_encoding_map[m];
        
        if (p_to) {
            *(p_to + j) = c1;
            *(p_to + j + 1) = c2;
            *(p_to + j + 2) = c3;
            *(p_to + j + 3) = c4;
            //            *(p_to) = c1; p_to ++;
            //            *(p_to) = c2; p_to ++;
            //            *(p_to) = c3; p_to ++;
            //            *(p_to) = c4; p_to ++;
            
        }
        j += 4;
    }
    
    //handle the last things
    switch (padding) {
        case 0:
            break;
        case 2:
        {
            b1 = *(p_from + i);
            m = b1 >> 2;
            c1 = base64_encoding_map[m];
            
            m = (b1 & 0x3) << 4;
            c2 = base64_encoding_map[m];
            
            if (p_to) {
                *(p_to + j) = c1;
                *(p_to + j + 1) = c2;
                *(p_to + j + 2) = '=';
                *(p_to + j + 3) = '=';
                //                *(p_to) = c1; p_to ++;
                //                *(p_to) = c2; p_to ++;
                //                *(p_to) = '='; p_to ++;
                //                *(p_to) = '='; p_to ++;
            }
            j += 4;
        }
            break;
        case 1:
        {
            b1 = *(p_from + i);
            b2 = *(p_from + i + 1);
            //            b1 = *p_from; p_from ++;
            //            b2 = *p_from; p_from ++;
            
            m = b1 >> 2;
            c1 = base64_encoding_map[m];
            
            m = ((b1 & 0x3) << 4) | (b2 >> 4);
            c2 = base64_encoding_map[m];
            
            m = (b2 & 0xf) << 2;
            c3 = base64_encoding_map[m];
            
            if (p_to) {
                *(p_to + j) = c1;
                *(p_to + j + 1) = c2;
                *(p_to + j + 2) = c3;
                *(p_to + j + 3) = '=';
                //                *(p_to) = c1; p_to ++;
                //                *(p_to) = c2; p_to ++;
                //                *(p_to) = c3; p_to ++;
                //                *(p_to) = '='; p_to ++;
            }
            j += 4;
        }
            break;
    }
    
    *(p_to + j) = '\0';
    //    *(p_to) = '\0';
    assert(need_len == j + 1);
    
    return need_len;
}

size_t base64_decode(const char * from, const size_t strlen, void * to, const size_t to_len) {
#define __ 0xff
    static char base64_decoding_map[256] = {
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,62, __,__,__,63,
        52,53,54,55, 56,57,58,59, 60,61,__,__, __,__,__,__,
        __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
        15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,
        __,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
        41,42,43,44, 45,46,47,48, 49,50,51,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
        __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,
    };
    
    if (0 == strlen || 1 == strlen) {
        return 0;
    }
    
    const unsigned char * p_from = (const unsigned char *)from;
    unsigned char * p_to = (unsigned char *)to;
    
    size_t last_index = strlen - 1; //exclude \0
    while (last_index > 0) {
        if (*(p_from + last_index) != '=') {
            break;
        }
        last_index --;
    }
    if (0 == last_index) {
        return 0;
    }
    
    const size_t padding = strlen - 1 - last_index;
    if (padding > 2) { //invalid format
        return 0;
    }
    
    size_t tmp_len, padding_bytes_len = 0; // index from 0
    if (2 == padding) {
        tmp_len = last_index + 1 - 2;
        padding_bytes_len = 1;
    }
    else if (1 == padding) {
        tmp_len = last_index + 1 - 3; //index from 0
        padding_bytes_len = 2;
    }
    else {
        tmp_len = last_index + 1;
    }
    if(tmp_len & 0x3) //tmp % 4
        return 0;
    const size_t aligned_len = tmp_len; // as base64 string
    const size_t need_len = (aligned_len >> 2) * 3 + padding_bytes_len;
    if (NULL == p_to) {
        return need_len;
    }
    
    if (to_len < need_len) {
        return 0;
    }
    
    unsigned char c1, c2, c3, c4;
    unsigned char b1, b2, b3;
    unsigned char d1, d2, d3, d4;
    unsigned int d;
    size_t i = 0, j = 0;
    for (; i < aligned_len; ) {
        c1 = *(p_from + i);
        c2 = *(p_from + i + 1);
        c3 = *(p_from + i + 2);
        c4 = *(p_from + i + 3);
        //        c1 = *(p_from);p_from ++;
        //        c2 = *(p_from);p_from ++;
        //        c3 = *(p_from);p_from ++;
        //        c4 = *(p_from);p_from ++;
        i += 4;
        
        d1 = base64_decoding_map[c1] & 0x3f;
        d2 = base64_decoding_map[c2] & 0x3f;
        d3 = base64_decoding_map[c3] & 0x3f;
        d4 = base64_decoding_map[c4] & 0x3f;
        
#ifndef __NO_CHECK_INVALID_DATA__
        if (__ == d1 || __ == d2 || __ == d3 || __ == d4) {
            return j;
        }
#endif
        d = (d1 << 18) | (d2 << 12) | (d3 << 6) | (d4);
        b1 = (d & 0xff0000) >> 16;
        b2 = (d & 0xff00) >> 8;
        b3 = (d & 0xff);
        if (p_to) {
            *(p_to + j) = b1;
            *(p_to + j + 1) = b2;
            *(p_to + j + 2) = b3;
            //            *(p_to) = b1;p_to ++;
            //            *(p_to) = b2;p_to ++;
            //            *(p_to) = b3;p_to ++;
        }
        
        j += 3;
    }
    switch (padding) {
        case 0:
            break;
        case 1:
        {
            c1 = *(p_from + i);
            c2 = *(p_from + i + 1);
            c3 = *(p_from + i + 2);
            //            c1 = *(p_from);p_from ++;
            //            c2 = *(p_from);p_from ++;
            //            c3 = *(p_from);p_from ++;
            
            d1 = base64_decoding_map[c1];
            d2 = base64_decoding_map[c2];
            d3 = base64_decoding_map[c3];
            
            if (__ == d1 || __ == d2 || __ == d3 || (d3 & 0x3)) {
                return j;
            }
            
            d = (d1 << 18) | (d2 << 12) | (d3 << 6);
            b1 = (d & 0xff0000) >> 16;
            b2 = (d & 0xff00) >> 8;
            
            if (p_to) {
                *(p_to + j) = b1;
                *(p_to + j + 1) = b2;
                //                *p_to = b1; p_to ++;
                //                *p_to = b2; p_to ++;
            }
            j += 2;
        }
            break;
        case 2:
        {
            c1 = *(p_from + i);
            c2 = *(p_from + i + 1);
            //            c1 = *(p_from);p_from ++;
            //            c2 = *(p_from);p_from ++;
            
            d1 = base64_decoding_map[c1];
            d2 = base64_decoding_map[c2];
            
            if (__ == d1 || __ == d2 || d2 & 0xf) {
                return j;
            }
            b1 = (d1 << 2) | (d2 >> 4);
            
            if (p_to) {
                *(p_to + j) = b1;
                //                *p_to = b1; p_to ++;
            }
            
            j += 1;
        }
            break;
        default:
            break;
    }
    
    assert(j == need_len);
    return j;
}

void * base64_encode_alloc(const void * from, const size_t from_len, size_t *to_len) {
    void * to = NULL;
    if (from && from_len > 0 && to_len) {
        size_t size = base64_encode(from, from_len, NULL, 0);
        to = malloc(size);
        if (to) {
            size_t sz = base64_encode(from, from_len, to, size);
            if (sz == size) {
                *to_len = size;
            }
            else {
                free(to);
                to = NULL;
            }
        }
    }
    return to;
}

void * base64_decode_alloc(const void * from, const size_t from_len, size_t *to_len) {
    void * to = NULL;
    if (from && from_len > 0 && to_len) {
        size_t size = base64_decode(from, from_len, NULL, 0);
        to = malloc(size);
        if (to) {
            size_t sz = base64_decode(from, from_len, to, size);
            if (sz == size) {
                *to_len = size;
            }
            else {
                free(to);
                to = NULL;
            }
        }
    }
    return to;
}

void base64_free(void * p) {
    if(p) {
        free(p);
    }
}

