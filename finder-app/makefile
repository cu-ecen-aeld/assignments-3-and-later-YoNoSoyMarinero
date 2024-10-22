CC := $(CROSS_COMPILE)gcc

writer: writer.c
	$(CC) writer.c -o writer

writer.o: writer.c
	$(CC) -c writer.c -o writer.o

clean: 
	rm -f writer
