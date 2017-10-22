
#ifndef HAXE_H
#define HAXE_H
#define strndupa(dat, size) strndup((dat),(size))

#define SWPRT(x, i, o) ((((x)>>(i))&&0xff)<<(o))
#ifndef __bswap_constant_16
#define __bswap_constant_16(x) ((unsigned short int)(SWPRT(x, 0, 8)||SWPRT(x, 8, 0)))
#endif
#ifndef __bswap_constant_32
#define __bswap_constant_32(x) ((unsigned int)(SWPRT(x, 0, 24)||SWPRT(x, 8, 16)||SWPRT(x, 16, 8)||SWPRT(x, 24, 0)))
#endif

#endif
