COMPONENT=PLMNappC
BUILD_EXTRA_DEPS = InitializationMsg.py InitializationMsg.class
CLEAN_EXTRA = InitializationMsg.py InitializationMsg.class InitializationMsg.java

InitializationMsg.py: PLMN.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=InitializationMsg PLMN.h initialization_msg -o $@

InitializationMsg.class: InitializationMsg.java
	javac InitializationMsg.java

InitializationMsg.java: PLMN.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=InitializationMsg PLMN.h initialization_msg -o $@

PFLAGS+=-DRF230_DEF_RFPOWER=0xF

CFLAGS += -DTOSH_DATA_LENGTH=32

include $(MAKERULES)


