/*
 * Snake Game Constants and Definitions
 * ARM64 Assembly Implementation for macOS
 */

#ifndef CONSTANTS_H
#define CONSTANTS_H

/* Game Configuration */
#define BOARD_WIDTH     80
#define BOARD_HEIGHT    25
#define INITIAL_SPEED   200     /* milliseconds per move */
#define SPEED_ACCEL     5       /* speed increase per food */
#define INITIAL_LENGTH  3       /* starting snake length */

/* Game Characters */
#define SNAKE_HEAD      'O'
#define SNAKE_BODY      'o'
#define FOOD_CHAR       '*'
#define WALL_CHAR       '#'
#define EMPTY_CHAR      ' '

/* Directions */
#define DIR_UP          0
#define DIR_DOWN        1
#define DIR_LEFT        2
#define DIR_RIGHT       3

/* Game States */
#define STATE_MENU      0
#define STATE_PLAYING   1
#define STATE_PAUSED    2
#define STATE_GAME_OVER 3
#define STATE_EXIT      4

/* Input Keys */
#define KEY_UP          65      /* Arrow Up */
#define KEY_DOWN        66      /* Arrow Down */
#define KEY_LEFT        68      /* Arrow Left */
#define KEY_RIGHT       67      /* Arrow Right */
#define KEY_SPACE       32      /* Space for pause */
#define KEY_Q           113     /* Q for quit */
#define KEY_ESC         27      /* Escape */

/* Memory Sizes */
#define STACK_SIZE      8192
#define HEAP_SIZE       4096
#define BUFFER_SIZE     8192

/* System Call Numbers (macOS ARM64) */
#define SYS_READ        3
#define SYS_WRITE       4
#define SYS_NANOSLEEP   240
#define SYS_IOCTL       54

/* File Descriptors */
#define STDIN           0
#define STDOUT          1
#define STDERR          2

/* ANSI Color Codes */
#define COLOR_RESET     "\033[0m"
#define COLOR_RED       "\033[31m"
#define COLOR_GREEN     "\033[32m"
#define COLOR_YELLOW    "\033[33m"
#define COLOR_BLUE      "\033[34m"
#define COLOR_MAGENTA   "\033[35m"
#define COLOR_CYAN      "\033[36m"
#define COLOR_WHITE     "\033[37m"

#endif /* CONSTANTS_H */