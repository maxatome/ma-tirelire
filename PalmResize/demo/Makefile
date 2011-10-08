## $Id: Makefile,v 1.2 2004/09/27 03:32:33 arpruss Exp $

all: resizedemo.prc

INCS = -I . -I .. -I ../../pb+/stable/nonfree/handera -I /sonysdk -I /sonysdk/Libraries -I /sonysdk/System

%.o: %.c
	m68k-palmos-gcc -Wall $(INCS) -c $*.c -o $*.o

resizedemo.prc: resizedemo.o ../DIA.o ../resize.o resizedemo_res.h bin.stamp
	m68k-palmos-gcc -o resizedemo -Wall resizedemo.o ../DIA.o ../resize.o -lpalmosglue
	build-prc --creator rDem --name "resizedemo" resizedemo *.bin

bin.stamp: resizedemo.rcp resizedemo_res.h
	m68k-palmos-gcc -E $(INCS) resizedemo.rcp | perl ../doaddition.pl > resizedemo.rcp.out
	pilrc resizedemo.rcp.out
	touch bin.stamp

clean:
	rm *.bin *.o resizedemo bin.stamp *.prc ../*.o *.rcp.out
