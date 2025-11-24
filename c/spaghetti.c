#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>


int main() {
    char s[100];
    printf("Enter a line: ");
    scanf("%[^\n]%*c", s); 
    printf("You entered: %s\n", s);
    return 0;
}

