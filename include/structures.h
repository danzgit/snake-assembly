/*
 * Data Structures for Snake Game
 * ARM64 Assembly Implementation for macOS
 */

#ifndef STRUCTURES_H
#define STRUCTURES_H

/* Snake Node Structure */
typedef struct SnakeNode {
    int x;                      /* X coordinate */
    int y;                      /* Y coordinate */
    struct SnakeNode* next;     /* Pointer to next segment */
} SnakeNode;

/* Game State Structure */
typedef struct GameState {
    int state;                  /* Current game state */
    int score;                  /* Current score */
    int direction;              /* Current direction */
    int speed;                  /* Current speed (ms) */
    int paused;                 /* Pause flag */
    SnakeNode* head;            /* Snake head pointer */
    SnakeNode* tail;            /* Snake tail pointer */
    int snake_length;           /* Current snake length */
    int food_x;                 /* Food X coordinate */
    int food_y;                 /* Food Y coordinate */
    char board[BOARD_HEIGHT][BOARD_WIDTH];  /* Game board */
} GameState;

/* Input Buffer Structure */
typedef struct InputBuffer {
    char buffer[256];           /* Input buffer */
    int length;                 /* Buffer length */
    int position;               /* Current position */
} InputBuffer;

/* Timer Structure */
typedef struct GameTimer {
    long long start_time;       /* Start time in nanoseconds */
    long long frame_time;       /* Frame time in nanoseconds */
    long long target_fps;       /* Target frames per second */
} GameTimer;

/* Memory Pool Structure */
typedef struct MemoryPool {
    void* pool_start;           /* Start of memory pool */
    void* pool_end;             /* End of memory pool */
    void* current;              /* Current allocation pointer */
    int available;              /* Available bytes */
} MemoryPool;

#endif /* STRUCTURES_H */