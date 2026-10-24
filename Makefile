# Gestor de turnos para servicios de salud
# Uso: make help
# Requiere: g++ (C++17), make, MariaDB Connector/C (libmariadb-dev) y cliente "mariadb".

CXX       ?= g++
BUILD     ?= release
BUILD_DIR := build/$(BUILD)

# Variables de entorno desde .env (opcional, ver .env.example)
-include .env
export

# Usuario administrador de MariaDB, solo para db-init y db-seed
DB_ADMIN_USER ?= root
DB_HOST       ?= localhost
DB_NAME       ?= gestor_turnos

CXXFLAGS_COMMON := -std=c++17 -Wall -Wextra -Wpedantic -pthread -Iinclude -Ithird_party

ifeq ($(BUILD),release)
  CXXFLAGS_MODE := -O2 -DNDEBUG
else ifeq ($(BUILD),debug)
  CXXFLAGS_MODE := -O0 -g
else ifeq ($(BUILD),tsan)
  CXXFLAGS_MODE := -O1 -g -fsanitize=thread
  LDFLAGS_MODE  := -fsanitize=thread
else
  $(error BUILD debe ser release, debug o tsan)
endif

DB_CFLAGS := $(shell mariadb_config --include 2>/dev/null || pkg-config --cflags libmariadb 2>/dev/null)
DB_LIBS   := $(shell mariadb_config --libs 2>/dev/null || pkg-config --libs libmariadb 2>/dev/null)

SERVER_SRCS := $(shell find src -name '*.cpp' 2>/dev/null)
LOAD_SRCS   := $(shell find tests/loadtest -name '*.cpp' 2>/dev/null)
SERVER_OBJS := $(SERVER_SRCS:%.cpp=$(BUILD_DIR)/obj/%.o)
LOAD_OBJS   := $(LOAD_SRCS:%.cpp=$(BUILD_DIR)/obj/%.o)

.DEFAULT_GOAL := all
.PHONY: all server loadtest run debug tsan db-init db-seed clean help

all: server loadtest ## Compila servidor y probador de carga

server: $(BUILD_DIR)/gestor_server ## Compila solo el servidor

loadtest: $(BUILD_DIR)/loadtest ## Compila solo el probador de carga

$(BUILD_DIR)/gestor_server: $(SERVER_OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS_MODE) $(DB_LIBS) -pthread

$(BUILD_DIR)/loadtest: $(LOAD_OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS_MODE) -pthread

$(BUILD_DIR)/obj/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_MODE) $(DB_CFLAGS) -MMD -MP -c $< -o $@

-include $(SERVER_OBJS:.o=.d) $(LOAD_OBJS:.o=.d)

run: server ## Compila y ejecuta el servidor
	./$(BUILD_DIR)/gestor_server

debug: ## Compila con símbolos de depuración (-O0 -g)
	$(MAKE) BUILD=debug all

tsan: ## Compila con ThreadSanitizer para detectar carreras de datos
	$(MAKE) BUILD=tsan all

db-init: ## Crea la base y las tablas (db/schema.sql)
	mariadb -h $(DB_HOST) -u $(DB_ADMIN_USER) -p < db/schema.sql

db-seed: ## Carga datos de prueba (db/seed.sql)
	mariadb -h $(DB_HOST) -u $(DB_ADMIN_USER) -p $(DB_NAME) < db/seed.sql

clean: ## Elimina la carpeta build/
	rm -rf build

help: ## Muestra esta ayuda
	@grep -hE '^[a-zA-Z_-]+:.*## ' Makefile | awk 'BEGIN{FS=":.*## "}{printf "  make %-10s %s\n", $$1, $$2}'
