CXX=g++
CXXFLAGS=-O2 -std=c++17 -Wall
TARGET=pathfinder
SRC=pathfinder.cpp
all: download-deps $(TARGET)
download-deps:
	@if [ ! -f json.hpp ]; then curl -sL https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp -o json.hpp; fi
$(TARGET): $(SRC) json.hpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRC)
clean:
	rm -f $(TARGET)
.PHONY: all clean download-deps
