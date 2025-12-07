SOURCE ?= ./fizz6.fth
VIERT := bash

default:
	FULL=1 $(VIERT) $(SOURCE)

mini:
	FULL=  $(VIERT) $(SOURCE)

lincom:
	LINCOM=1 $(VIERT) $(SOURCE)
