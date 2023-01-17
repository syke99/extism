@OSFLAG := 
ifeq ($(OS),Windows_NT)
	OSFLAG = Windows
else 
	SHELL_S := $(shell uname -s)
	ifeq ($(SHELL_S),Darwin)
		OSFLAG = OSX
	else ifeq ($(SHELL_S),Linux)
		OSFLAG = Linux
	endif

	SHELL_P := $(shell uname -p)
	ifeq ($(SHELL_P),x86_64)
		OSFLAG = AMD64
	endif

	ifneq ($(filter %86,$(UNAME_P)),)
		OSFLAG = -D IA32
		endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		OSFLAG = -D ARM
	endif
endif

print-os:
	@echo $(OSFLAG)

prepare-gcc: import_headers.c
		@gcc -c import_headers.c

prepare-cl: import_headers.c
		@cl -TC -c import_headers.c