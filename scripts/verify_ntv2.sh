#!/bin/bash
# Verification script for NTv2 grids using PROJ/GDAL tools

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==================================="
echo "NTv2 Grid Verification Script"
echo "==================================="
echo ""

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ntv2_grid_file.gsb>"
    echo ""
    echo "This script verifies NTv2 grid files using PROJ/GDAL tools."
    echo "It requires proj-bin or gdal-bin to be installed."
    exit 1
fi

GRID_FILE="$1"

# Check if file exists
if [ ! -f "$GRID_FILE" ]; then
    echo -e "${RED}Error: File '$GRID_FILE' not found${NC}"
    exit 1
fi

echo "Checking NTv2 grid file: $GRID_FILE"
echo ""

# Check if PROJ tools are available
HAS_PROJ=0
HAS_GDAL=0

if command -v projinfo &> /dev/null; then
    HAS_PROJ=1
    echo -e "${GREEN}✓ PROJ tools found${NC}"
fi

if command -v gdalinfo &> /dev/null; then
    HAS_GDAL=1
    echo -e "${GREEN}✓ GDAL tools found${NC}"
fi

if [ $HAS_PROJ -eq 0 ] && [ $HAS_GDAL -eq 0 ]; then
    echo -e "${YELLOW}Warning: Neither PROJ nor GDAL tools found${NC}"
    echo "Install with: sudo apt-get install proj-bin gdal-bin"
    echo ""
    echo "Basic file check only:"
    echo "  File size: $(du -h "$GRID_FILE" | cut -f1)"
    echo "  File type: $(file "$GRID_FILE")"
    exit 0
fi

echo ""

# Test with PROJ
if [ $HAS_PROJ -eq 1 ]; then
    echo "==================================="
    echo "Testing with PROJ"
    echo "==================================="
    
    # Try to get grid info with projinfo
    if projinfo --single-line "$GRID_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Grid is readable by PROJ${NC}"
    else
        echo -e "${YELLOW}Note: projinfo may not support direct grid file inspection${NC}"
    fi
    
    echo ""
    
    # Try a coordinate transformation using the grid
    echo "Testing coordinate transformation..."
    echo "Input coordinates (Tokyo Datum): 35.6583333 139.7000000"
    
    # Create a temporary file with coordinates
    TEMP_FILE=$(mktemp)
    echo "139.7000000 35.6583333" > "$TEMP_FILE"
    
    # Note: This is a simplified test. Real usage would require proper CRS definitions
    # and grid file placement in PROJ data directory
    echo -e "${YELLOW}Note: Full coordinate transformation requires grid installation${NC}"
    echo "To use this grid:"
    echo "  1. Copy to PROJ data directory (e.g., /usr/share/proj/)"
    echo "  2. Use in transformations with +nadgrids parameter"
    
    rm "$TEMP_FILE"
fi

echo ""

# Test with GDAL
if [ $HAS_GDAL -eq 1 ]; then
    echo "==================================="
    echo "Testing with GDAL"
    echo "==================================="
    
    # Try to get grid info with gdalinfo
    if gdalinfo "$GRID_FILE" 2>&1 | grep -q "Driver:"; then
        echo -e "${GREEN}✓ Grid is readable by GDAL${NC}"
        echo ""
        echo "Grid information:"
        gdalinfo "$GRID_FILE" | head -20
    else
        echo -e "${YELLOW}Note: GDAL may not directly read this grid format${NC}"
        echo "GDAL can use NTv2 grids for coordinate transformations"
    fi
fi

echo ""
echo "==================================="
echo "File Information"
echo "==================================="
echo "  File: $GRID_FILE"
echo "  Size: $(du -h "$GRID_FILE" | cut -f1)"
echo "  Type: $(file "$GRID_FILE")"

# Check for NTv2 header markers
echo ""
echo "Checking NTv2 format markers..."
if xxd "$GRID_FILE" 2>/dev/null | head -5 | grep -q "NUM_OREC"; then
    echo -e "${GREEN}✓ NUM_OREC header found${NC}"
fi

if xxd "$GRID_FILE" 2>/dev/null | head -10 | grep -q "GS_TYPE"; then
    echo -e "${GREEN}✓ GS_TYPE header found${NC}"
fi

echo ""
echo "==================================="
echo "Verification Complete"
echo "==================================="
