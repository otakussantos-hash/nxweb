#---------------------------------------------------------------------------------
# NXWeb - Nintendo Switch homebrew web browser
# Build with devkitPro (devkitA64 + libnx + switch portlibs)
#---------------------------------------------------------------------------------
.SUFFIXES:

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITPRO)/libnx/switch_rules

TARGET		:=	nxweb
BUILD		:=	build

# litehtml is cloned into third_party/ by scripts/fetch-deps.sh
LITEHTML	:=	third_party/litehtml

SOURCES		:=	source $(LITEHTML)/src $(LITEHTML)/src/gumbo
DATA		:=	data
INCLUDES	:=	source \
			$(LITEHTML)/include \
			$(LITEHTML)/include/litehtml \
			$(LITEHTML)/src/gumbo/include \
			$(LITEHTML)/src/gumbo/include/gumbo
ROMFS		:=	romfs

APP_TITLE	:=	NXWeb
APP_AUTHOR	:=	NXWeb contributors
APP_VERSION	:=	0.1.0

# No custom icon yet (drop a 256x256 icon.jpg here and remove this line to use it)
NO_ICON		:=	1

#---------------------------------------------------------------------------------
# Libraries, resolved through the devkitPro pkg-config wrapper
#---------------------------------------------------------------------------------
PKG_CONFIG	:=	$(DEVKITPRO)/portlibs/switch/bin/aarch64-none-elf-pkg-config
PKG_CFLAGS	:=	$(shell $(PKG_CONFIG) --cflags sdl2 SDL2_ttf libcurl 2>/dev/null)
PKG_LIBS	:=	$(shell $(PKG_CONFIG) --libs --static sdl2 SDL2_ttf libcurl 2>/dev/null)

ifeq ($(strip $(PKG_LIBS)),)
# Fallback if pkg-config is not available
PKG_LIBS	:=	-lSDL2_ttf -lSDL2 -lfreetype -lbz2 -lpng -lz \
			-lcurl -lmbedtls -lmbedx509 -lmbedcrypto \
			-lEGL -lglapi -ldrm_nouveau
endif

ARCH		:=	-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE

CFLAGS		:=	-g -Wall -O2 -ffunction-sections $(ARCH) $(DEFINES) $(PKG_CFLAGS)
CFLAGS		+=	$(INCLUDE) -D__SWITCH__

CXXFLAGS	:=	$(CFLAGS) -std=gnu++17

ASFLAGS		:=	-g $(ARCH)
LDFLAGS		=	-specs=$(DEVKITPRO)/libnx/switch.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS		:=	$(PKG_LIBS) -lnx

LIBDIRS		:=	$(PORTLIBS) $(LIBNX)

#---------------------------------------------------------------------------------
# Everything below is the standard devkitPro libnx template
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifeq ($(strip $(CPPFILES)),)
	export LD	:=	$(CC)
else
	export LD	:=	$(CXX)
endif

export OFILES_BIN	:=	$(addsuffix .o,$(BINFILES))
export OFILES_SRC	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES		:=	$(OFILES_BIN) $(OFILES_SRC)
export HFILES_BIN	:=	$(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.jpg)
	ifneq (,$(findstring $(TARGET).jpg,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).jpg
	else
		ifneq (,$(findstring icon.jpg,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.jpg
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_ICON)),)
	export NROFLAGS += --icon=$(APP_ICON)
endif

ifeq ($(strip $(NO_NACP)),)
	export NROFLAGS += --nacp=$(CURDIR)/$(TARGET).nacp
endif

ifneq ($(ROMFS),)
	export NROFLAGS += --romfsdir=$(CURDIR)/$(ROMFS)
endif

.PHONY: $(BUILD) clean all

all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).nro $(TARGET).nacp $(TARGET).elf

else
.PHONY:	all

DEPENDS	:=	$(OFILES:.o=.d)

all	:	$(OUTPUT).nro

ifeq ($(strip $(NO_NACP)),)
$(OUTPUT).nro	:	$(OUTPUT).elf $(OUTPUT).nacp
else
$(OUTPUT).nro	:	$(OUTPUT).elf
endif

$(OUTPUT).elf	:	$(OFILES)

$(OFILES_SRC)	:	$(HFILES_BIN)

%.bin.o	%_bin.h :	%.bin
	@echo $(notdir $<)
	@$(bin2o)

-include $(DEPENDS)

endif
