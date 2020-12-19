#include "acia.h"
#include <stdio.h>

void acia_write(uint8_t reg, uint8_t val)
{
    if(reg == 0)
    {
        printf("%c", val);
    }
}

uint8_t acia_read(uint8_t reg)
{
    return 0;
}
