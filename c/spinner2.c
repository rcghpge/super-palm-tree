// c/spinner.c
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #include <windows.h>
  static void sleep_ms(unsigned int ms) { Sleep(ms); }
#else
  #include <time.h>
  static void sleep_ms(unsigned int ms) {
    struct timespec ts;
    ts.tv_sec  = ms / 1000u;
    ts.tv_nsec = (long)(ms % 1000u) * 1000000L;
    nanosleep(&ts, NULL);
  }
#endif

int main(void) {
  const char frames[] = "|/-\\";
  size_t frame = 0;

  printf("Loading ");
  fflush(stdout);

  // spin for ~3 seconds (30 frames at 100 ms each)
  for (int tick = 0; tick < 30; ++tick) {
    printf("%c\b", frames[frame]);      // print spinner frame, then backspace
    fflush(stdout);
    frame = (frame + 1) % (sizeof(frames) - 1);
    sleep_ms(100);
  }

#ifdef _WIN32
  printf("done!\n");
#else
  printf("✓ Done!\n");
#endif

  return 0;
}
