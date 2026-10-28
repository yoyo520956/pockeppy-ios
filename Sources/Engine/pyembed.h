#ifndef PPY_EMBED_H
#define PPY_EMBED_H
#include <stdbool.h>

/// 初始化内嵌 CPython（homePath = bundle 内 pyhome 目录，含 stdlib）
bool ppy_init(const char *homePath);

/// 执行用户代码，返回 JSON 字符串（malloc 缓冲）：
/// {"ok":bool,"stdout":"...","stderr":"...","tb":"..."}，调用方负责 ppy_free
char *ppy_run(const char *code);

void ppy_free(char *p);

/// 解释器版本串（静态存储，无需释放）
const char *ppy_version(void);

#endif // PPY_EMBED_H
