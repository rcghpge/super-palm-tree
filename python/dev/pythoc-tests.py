from pythoc import compile, linear, consume, void, ptr, i8, i32, struct
from pythoc.libc.stdlib import malloc, free

@compile
def lmalloc(size: i32) -> struct[ptr[i8], linear]:
    print("Allocating", size)
    return malloc(size), linear()

@compile
def lfree(ptr: ptr[i8], prf: linear) -> void:
    print("Freeing", ptr)
    consume(prf)
    free(ptr)

@compile
def safe_usage() -> void:
    mem, prf = lmalloc(100)
    mem2, prf2 = lmalloc(200)
    print("Hello from", safe_usage)
    lfree(mem, prf2)
    lfree(mem2, prf)
    print("Done")

safe_usage()
