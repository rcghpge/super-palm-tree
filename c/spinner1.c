#include <stdio.h>
#include <unistd.h> // For usleep on Unix-like systems
// #include <windows.h> // For Sleep on Windows systems

void display_spinner(int duration_seconds) {
    char spinner_frames[] = {'|', '/', '-', '\\'};
    int num_frames = sizeof(spinner_frames) / sizeof(spinner_frames[0]);
    int frame_index = 0;

    printf("Loading... ");
    fflush(stdout);

    for (int i = 0; i < duration_seconds * 10; ++i) { // Adjust for speed and duration
        printf("\rLoading... %c", spinner_frames[frame_index]);
        fflush(stdout);

        // Pause for a short duration
        usleep(100000); // 100 milliseconds (100,000 microseconds) for Unix-like systems
        // Sleep(100); // 100 milliseconds for Windows systems

        frame_index = (frame_index + 1) % num_frames;
    }
    printf("\rLoading... Done!\n");
}

int main() {
    display_spinner(5);
    return 0;
}
