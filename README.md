# nt - NTv2 Grid Converter

A Ruby-based tool for converting Japanese geodetic transformation parameters (tky2jgd.par) and Jordan transformation parameters to NTv2 grid format.

## Overview

This tool converts datum transformation parameter files into the NTv2 (National Transformation version 2) binary grid format, which is widely supported by GIS software including PROJ, GDAL, and various commercial GIS applications.

**NTv2** is a standardized format for storing datum transformation grids. It uses a binary format to efficiently store latitude and longitude shift values across a geographic area.

**Supported input formats:**
- **tky2jgd.par**: Japanese geodetic transformation parameters (Tokyo Datum → JGD2000/JGD2011)
- **Jordan transformation parameters**: 2D conformal coordinate transformations

## Features

- ✅ Parse tky2jgd.par format (Tokyo Datum to JGD2000/JGD2011)
- ✅ Parse Jordan transformation parameters (2D conformal transformations)
- ✅ Automatic input format detection
- ✅ Convert transformation parameters to NTv2 binary grid format
- ✅ Command-line interface with multiple options
- ✅ Download tky2jgd.par from GSI (built-in fetch command)
- ✅ Statistics and validation
- ✅ JSON export for debugging
- ✅ Sample data included for both formats
- ✅ Unit tests with minitest
- ✅ PROJ/GDAL verification script
- ✅ CC0 public domain license

## Installation

### Prerequisites

- Ruby 2.7 or higher
- Optional: PROJ and GDAL tools for grid verification

### Clone and Setup

```bash
git clone https://github.com/hfu/nt.git
cd nt
```

No additional gem dependencies required - uses only Ruby standard library!

## Usage

### Basic Conversion

Convert a tky2jgd.par file to NTv2 format:

```bash
./bin/nt_convert data/samples/tokyo_sample.par
```

This creates `tokyo_sample.gsb` in the same directory.

### Specify Output File

```bash
./bin/nt_convert -o output.gsb data/samples/tokyo_sample.par
```

### Verbose Output

```bash
./bin/nt_convert -v data/samples/tokyo_sample.par
```

### Show Statistics Only

```bash
./bin/nt_convert --stats data/samples/tokyo_sample.par
```

### Export to JSON

```bash
./bin/nt_convert -f json data/samples/tokyo_sample.par
```

### Command-Line Options

```
Usage: nt_convert [options] input_file

Options:
    -o, --output FILE          Output file (default: input_file.gsb)
    -f, --format FORMAT        Output format: ntv2, json (default: ntv2)
    -i, --input-format FORMAT  Input format: auto, tky2jgd, jordan (default: auto)
    -v, --verbose              Verbose output
    -s, --stats                Show statistics only
    -h, --help                 Show this help message
        --version              Show version
```

## Input Format: tky2jgd.par

The tky2jgd.par format contains transformation parameters from Tokyo Datum to JGD2000/JGD2011:

```
# Format: MeshCode Lat Lon dB(sec) dL(sec) dH(m)
5339357700 35.6583333 139.7000000 -11.5325 4.2451 -36.12
5339357701 35.6583333 139.7083333 -11.5318 4.2447 -36.11
```

Where:
- **MeshCode**: Third mesh code (1km mesh) identifier
- **Lat**: Latitude in decimal degrees
- **Lon**: Longitude in decimal degrees
- **dB**: Latitude shift in arcseconds (Tokyo → JGD)
- **dL**: Longitude shift in arcseconds (Tokyo → JGD)
- **dH**: Height shift in meters (Tokyo → JGD)

### Obtaining tky2jgd.par

The official tky2jgd.par file can be downloaded from the Geospatial Information Authority of Japan (GSI):

**Using the built-in fetch command** (recommended):
```bash
./bin/nt_fetch
```

Or with verbose output:
```bash
./bin/nt_fetch -v
```

**Download URL**: https://vldb.gsi.go.jp/sokuchi/surveycalc/tky2jgd/download/

**Manual download**:
```bash
# Download tky2jgd.par (approximately 10MB)
curl -O https://vldb.gsi.go.jp/sokuchi/surveycalc/tky2jgd/download/tky2jgd.par

# Convert to NTv2
./bin/nt_convert tky2jgd.par
```

The file contains approximately 440,000 grid points covering Japan.

## Input Format: Jordan Transformation Parameters

Jordan transformation parameters describe 2D conformal coordinate transformations. The format supports:

```
# Format: ID X Y dX dY dZ
PT1 35.8500 31.9500 0.00012 -0.00015 2.5
PT2 35.9000 31.9500 0.00013 -0.00015 2.6
```

Where:
- **ID**: Point identifier (optional)
- **X**: Longitude in decimal degrees
- **Y**: Latitude in decimal degrees
- **dX**: Longitude shift in degrees
- **dY**: Latitude shift in degrees
- **dZ**: Height shift in meters (optional)

**Supported formats:**
- `X Y dX dY` - Basic 2D transformation (4 columns)
- `ID X Y dX dY` - With point identifier (5 columns)
- `ID X Y dX dY dZ` - With height component (6 columns)

Both space-separated and comma-separated values are supported.

**Example conversions:**
```bash
# Convert Jordan parameters to NTv2
./bin/nt_convert data/samples/jordan_sample.txt

# Specify input format explicitly
./bin/nt_convert -i jordan transformation_params.txt

# Auto-detect format (default)
./bin/nt_convert transformation_params.txt
```

### Complete Workflow

```bash
# 1. Download tky2jgd.par
./bin/nt_fetch -v

# 2. Convert to NTv2
./bin/nt_convert -v tky2jgd.par

# 3. Verify the output
./scripts/verify_ntv2.sh tky2jgd.gsb
```

## Output Format: NTv2

The NTv2 format is a binary grid shift format consisting of:

1. **Overview Record**: General information about the grid
   - Number of sub-grids
   - Source and target datum
   - Ellipsoid parameters (Bessel 1841 → GRS80)

2. **Sub-Grid Records**: One or more regional grids
   - Grid boundaries and spacing
   - Latitude/longitude shift values
   - Accuracy estimates

The output `.gsb` (Grid Shift Binary) file can be used with:
- PROJ: `+nadgrids=tokyo_sample.gsb`
- GDAL: Place in PROJ data directory
- GIS software: Import as transformation grid

## Verification

### Using the Verification Script

```bash
./scripts/verify_ntv2.sh data/samples/tokyo_sample.gsb
```

This script checks:
- File format validity
- NTv2 header markers
- PROJ/GDAL compatibility (if installed)

### Manual Verification with PROJ

```bash
# Install PROJ tools
sudo apt-get install proj-bin

# Check grid info
projinfo tokyo_sample.gsb
```

### Manual Verification with GDAL

```bash
# Install GDAL tools
sudo apt-get install gdal-bin

# Check grid info
gdalinfo tokyo_sample.gsb
```

## Development

### Running Tests

```bash
# Run all tests
ruby test/test_tky2jgd_parser.rb
ruby test/test_ntv2_writer.rb

# Or with minitest
ruby -I lib:test test/test_*.rb
```

### Project Structure

```
nt/
├── bin/
│   ├── nt_convert          # CLI tool for conversion
│   └── nt_fetch            # CLI tool for downloading tky2jgd.par
├── lib/
│   ├── tky2jgd_parser.rb   # Parser for tky2jgd.par
│   ├── jordan_parser.rb    # Parser for Jordan parameters
│   └── ntv2_writer.rb      # NTv2 binary writer
├── test/
│   ├── test_tky2jgd_parser.rb
│   ├── test_jordan_parser.rb
│   ├── test_ntv2_writer.rb
│   └── run_tests.rb        # Test runner
├── data/
│   └── samples/
│       ├── tokyo_sample.par    # Sample tky2jgd input
│       ├── tokyo_sample.gsb    # Sample tky2jgd output
│       ├── jordan_sample.txt   # Sample Jordan input
│       └── jordan_sample.gsb   # Sample Jordan output
├── scripts/
│   └── verify_ntv2.sh      # Verification script
├── .gitignore
├── LICENSE                 # CC0 1.0 Universal
└── README.md
```

## Technical Details

### Coordinate Systems

- **Tokyo Datum**: Uses Bessel 1841 ellipsoid
  - Semi-major axis: 6,377,397.155 m
  - Semi-minor axis: 6,356,078.963 m

- **JGD2000/JGD2011**: Uses GRS80 ellipsoid
  - Semi-major axis: 6,378,137.0 m
  - Semi-minor axis: 6,356,752.314 m

### Transformation Method

The transformation is performed using a grid-based approach:
1. Interpolate shift values from nearby grid points
2. Apply latitude and longitude shifts
3. Result in JGD2000/JGD2011 coordinates

### Grid Spacing

The tky2jgd.par file typically uses:
- **1st mesh**: 40km × 40km (regional coverage)
- **2nd mesh**: 5km × 5km
- **3rd mesh**: 1km × 1km (standard resolution)

## References

### Standards and Specifications

- **NTv2 Format**: Natural Resources Canada, "NTv2 Developer's Guide"
- **JGD2000**: Geospatial Information Authority of Japan
- **tky2jgd**: GSI datum transformation parameters

### Related Software

- **PROJ**: https://proj.org/
- **GDAL**: https://gdal.org/
- **GSI Tools**: https://vldb.gsi.go.jp/sokuchi/surveycalc/

## License

This project is released under the **CC0 1.0 Universal** license, placing it in the public domain. You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.

See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Since this is CC0 licensed:
- No attribution required
- No copyright restrictions
- Use freely in any project

## Author

Created as part of the nt (NTv2 converter) project.

## Acknowledgments

- Geospatial Information Authority of Japan (GSI) for providing transformation parameters
- PROJ and GDAL communities for NTv2 format documentation

