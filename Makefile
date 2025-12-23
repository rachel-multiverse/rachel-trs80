# Rachel TRS-80 Client Makefile

ZMAC ?= zmac
PASMO ?= pasmo

BUILD_DIR = build
SRC_DIR = src

TARGET = $(BUILD_DIR)/rachel.cmd

.PHONY: all clean

all: $(BUILD_DIR) $(TARGET)
	@echo "Built: $(TARGET)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Use Pasmo as fallback if zmac not available
$(TARGET): $(SRC_DIR)/main.asm $(SRC_DIR)/*.asm $(SRC_DIR)/net/*.asm
	cd $(SRC_DIR) && $(PASMO) --cmd main.asm ../$(TARGET) || $(ZMAC) -o ../$(TARGET) main.asm

clean:
	rm -rf $(BUILD_DIR)
