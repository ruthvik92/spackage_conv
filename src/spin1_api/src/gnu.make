#
# Makefile for spin1_api using GNU tools
#

THUMB = no
CTIME = $(shell perl -e "print time")

LIB_DIR = .
INC_DIR = .


CC := arm-none-linux-gnueabi-gcc -c -O1 -nostdlib -mthumb-interwork \
      -march=armv5te -std=gnu99 -I $(INC_DIR)
CT := $(CC)
AS := arm-none-linux-gnueabi-as -mthumb-interwork -march=armv5te --defsym GNU=1
LD := arm-none-linux-gnueabi-ld
OC := arm-none-linux-gnueabi-objcopy

ifeq ($(THUMB),yes)
  CT += -mthumb -DTHUMB
  AS += --defsym THUMB=1
endif


API_OBJS = sark_init.o sark.o spin1_isr.o spin1_api.o spinn_io.o

lib: $(API_OBJS)
	$(LD) -T sark.lnk -nostdlib -i -o spin1_api_gnulib.o $(API_OBJS)


install: spin1_api_gnulib.o spin1_api.h spinn_io.h spinn_sdp.h spinnaker.h
	cp spin1_api_gnulib.o $(LIB_DIR)
	chmod 644 $(LIB_DIR)/spin1_api_gnulib.o
	cp spin1_api.h spinn_io.h spinn_sdp.h spinnaker.h $(INC_DIR)
	chmod 644 $(INC_DIR)/*


sark_init.o: spinnaker.h sark_init.s
	h2asm $(INC_DIR)/spinnaker.h | arm2gas > spinnaker.gas
	arm2gas sark_init.s > sark_init.gas
	$(AS) --defsym SARK_API=1 -o sark_init.o sark_init.gas

sark.o: sark.c $(INC_DIR)/spinnaker.h spin1_api.h spin1_api_params.h
	$(CT) -DSARK_API -DCTIME=$(CTIME) sark.c

spin1_api.o: spin1_api.c spinnaker.h spin1_api.h spinn_io.h spin1_api_params.h
	$(CT) spin1_api.c

spin1_isr.o: spin1_isr.c spin1_api.h spin1_api_params.h spinnaker.h
	$(CC) spin1_isr.c

spinn_io.o: spinn_io.c spinn_io.h spinnaker.h
	$(CT) spinn_io.c


clean:
	rm -f $(API_OBJS) spinnaker.s spinnaker.gas sark_init.gas *~
