@OSFLAG := 
ifeq ($(OS),Windows_NT)
	OSFLAG = Windows
else 
	OSFLAG = Nix-Type
endif

prepare:
ifeq ($(OSFLAG),Windows)
	$(MAKE) prepare-cl
else
	$(MAKE) prepare-gcc
endif

prepare-gcc: import_headers.c
		@gcc -c import_headers.c

prepare-cl: import_headers.c
		@cl -TC -c import_headers.c