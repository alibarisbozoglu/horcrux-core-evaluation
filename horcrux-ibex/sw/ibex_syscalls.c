// Minimal newlib syscalls for the Ibex Simple System: stdout goes to the SIM_CTRL output
// register (ibex_simple_system.log), the heap grows from the end of .bss.
#include <stddef.h>
#include <sys/stat.h>
#include "simple_system_common.h"

extern char _bss_end[];
static char *heap = _bss_end;

int _write(int fd, const char *buf, int len) { for (int i = 0; i < len; i++) putchar(buf[i]); return len; }
int _read(int fd, char *buf, int len) { return 0; }
int _close(int fd) { return -1; }
int _fstat(int fd, struct stat *st) { st->st_mode = S_IFCHR; return 0; }
int _isatty(int fd) { return 1; }
int _lseek(int fd, int off, int whence) { return 0; }
int _kill(int pid, int sig) { return -1; }
int _getpid(void) { return 1; }
void _exit(int code) { sim_halt(); for (;;) ; }
void *_sbrk(ptrdiff_t inc) { char *p = (char *)(((size_t)heap + 7) & ~(size_t)7); heap = p + inc; return p; }
