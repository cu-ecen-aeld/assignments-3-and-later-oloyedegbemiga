CC := $(CROSS_COMPILE)gcc

TARGET := writer

SRC := writer.c


CFLAGS := -Wall -Werror

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET) *.o

.PHONY: all clean