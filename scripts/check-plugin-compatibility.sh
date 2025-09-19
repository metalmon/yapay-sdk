#!/bin/bash

# Plugin Compatibility Check Script for YAPAY SDK
# Проверяет совместимость плагинов с эталонным образом builder

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔌 YAPAY SDK Plugin Compatibility Check${NC}"
echo "=============================================="

# Проверяем, что мы в правильной директории
if [ ! -f "go.mod" ]; then
    echo -e "${RED}❌ Error: go.mod not found. Run this script from SDK root.${NC}"
    exit 1
fi

# Проверяем доступность builder образа
echo -e "${YELLOW}🔍 Checking builder image availability...${NC}"
if ! docker image inspect metalmon/yapay:builder >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Builder image not found locally, pulling...${NC}"
    docker pull metalmon/yapay:builder || {
        echo -e "${RED}❌ Failed to pull builder image${NC}"
        echo -e "${YELLOW}Please ensure metalmon/yapay:builder is available${NC}"
        exit 1
    }
fi

# Функция для проверки сборки плагинов
check_plugin_build() {
    local plugin_dir=$1
    local plugin_name=$(basename "$plugin_dir")
    
    echo -e "${YELLOW}🔍 Checking plugin: $plugin_name${NC}"
    
    if [ ! -f "$plugin_dir/go.mod" ]; then
        echo -e "${YELLOW}  ⚠️  No go.mod found, skipping${NC}"
        return 0
    fi
    
    # Пробуем собрать плагин с эталонным образом
    if docker run --rm \
        -v "$(pwd)":/workspace \
        -w "/workspace/$plugin_dir" \
        metalmon/yapay:builder \
        sh -c 'cp /app/go.mod . && cp /app/go.sum . && cp -r /app/vendor . && CGO_ENABLED=1 go build -buildmode=plugin -o test.so .' 2>/dev/null; then
        echo -e "${GREEN}  ✅ Plugin $plugin_name builds successfully${NC}"
        rm -f "$plugin_dir/test.so"
        return 0
    else
        echo -e "${RED}  ❌ Plugin $plugin_name failed to build${NC}"
        return 1
    fi
}

# Функция для проверки совместимости с SDK
check_sdk_compatibility() {
    echo -e "${BLUE}📋 Checking SDK compatibility...${NC}"
    
    # Проверяем, что SDK использует совместимые зависимости
    if docker run --rm \
        -v "$(pwd)":/workspace \
        -w "/workspace" \
        metalmon/yapay:builder \
        sh -c 'go mod download && go mod verify' 2>/dev/null; then
        echo -e "${GREEN}  ✅ SDK dependencies are compatible${NC}"
        return 0
    else
        echo -e "${RED}  ❌ SDK dependencies are incompatible${NC}"
        return 1
    fi
}

# Счетчики
total_plugins=0
broken_plugins=0
broken_list=()

echo -e "${BLUE}📋 Checking all plugins...${NC}"

# Проверяем SDK совместимость
if ! check_sdk_compatibility; then
    echo -e "${RED}❌ SDK is not compatible with builder image${NC}"
    exit 1
fi

# Проверяем плагины в src/ (основные плагины)
if [ -d "src" ]; then
    for plugin_dir in src/*; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/go.mod" ]; then
            total_plugins=$((total_plugins + 1))
            if ! check_plugin_build "$plugin_dir"; then
                broken_plugins=$((broken_plugins + 1))
                broken_list+=("$(basename "$plugin_dir")")
            fi
        fi
    done
fi

# Проверяем плагины в examples/ (примеры плагинов)
if [ -d "examples" ]; then
    for plugin_dir in examples/*; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/go.mod" ]; then
            total_plugins=$((total_plugins + 1))
            if ! check_plugin_build "$plugin_dir"; then
                broken_plugins=$((broken_plugins + 1))
                broken_list+=("$(basename "$plugin_dir")")
            fi
        fi
    done
fi

# Проверяем плагины в testing/ (тестовые плагины)
if [ -d "testing" ]; then
    for plugin_dir in testing/*; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/go.mod" ]; then
            total_plugins=$((total_plugins + 1))
            if ! check_plugin_build "$plugin_dir"; then
                broken_plugins=$((broken_plugins + 1))
                broken_list+=("$(basename "$plugin_dir")")
            fi
        fi
    done
fi

echo ""
echo -e "${BLUE}📊 SDK Compatibility Report${NC}"
echo "=============================="
echo -e "Total plugins checked: ${BLUE}$total_plugins${NC}"
echo -e "Working plugins: ${GREEN}$((total_plugins - broken_plugins))${NC}"
echo -e "Broken plugins: ${RED}$broken_plugins${NC}"

if [ $broken_plugins -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ COMPATIBILITY ISSUES DETECTED!${NC}"
    echo -e "${RED}The following plugins are broken:${NC}"
    for plugin in "${broken_list[@]}"; do
        echo -e "${RED}  - $plugin${NC}"
    done
    echo ""
    echo -e "${YELLOW}🚨 RECOMMENDATION:${NC}"
    echo -e "${YELLOW}1. Update plugin dependencies to match builder image${NC}"
    echo -e "${YELLOW}2. Check if builder image needs updating${NC}"
    echo -e "${YELLOW}3. Contact YAPAY team for support${NC}"
    echo -e "${YELLOW}4. Use 'make build-plugin-NAME' to rebuild specific plugin${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ ALL PLUGINS COMPATIBLE${NC}"
    echo -e "${GREEN}SDK is ready for plugin development!${NC}"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo -e "${BLUE}  - Create new plugins in src/ directory${NC}"
    echo -e "${BLUE}  - Use 'make build-plugin-NAME' to build plugins${NC}"
    echo -e "${BLUE}  - Test plugins with 'make test-plugins'${NC}"
    exit 0
fi
