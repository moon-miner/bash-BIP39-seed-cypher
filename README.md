# Bash BIP39 Seed Cipher (currently beta)
A secure and efficient tool for encoding and decoding BIP39 seed phrases while maintaining the BIP39 word format.

## 📋 Table of Contents
- Project Description
- Installation
  - Method 1: Blockchain Installation
  - Method 2: Traditional Installation
- Usage
  - Requirements
  - Examples
  - Interactive Flow
- Security
  - Security Features
  - Security Strengths
  - Security Analysis
  - Security Considerations
- Technical Details
  - Implementation Notes
  - Performance
  - Script Analyzer
    - Analyzer Requirements
    - Analyzer Installation
    - Analyzer Usage
    - Analyzer Output
    - Analysis Features
- Legal
  - License
  - Disclaimer
- Contributing

## 📝 Project Description
This script provides a secure way to transform BIP39 seed phrases into alternative valid BIP39 phrases and back, using password-based encryption. It maintains the original security properties of BIP39 while adding an extra layer of protection through reversible transformation.

The transformation is:
- Completely reversible
- Password-dependent
- Statistically uniform
- Maintaining BIP39 format

## 🔥 Installation Methods (BETA VERSION)

### Method 1: Blockchain Installation (Recommended)
The main script scypher.sh is stored securely on the blockchain, ensuring it will never be lost. To install:

Get the loader script directly from the blockchain:
```bash
curl -X GET https://api.sigmaspace.io/api/v1/tokens/b1715708cdc9c9f42f7de433061711b2ad79814a2e837e6aa9dd9de16b82d9d4 | jq -r '.description' | base64 -d > scypherdload.sh
chmod +x scypherdload.sh
```

Verify the loader script integrity:
```bash
# The MD5 hash of scypherdload.sh should be:
393cd4d53ac3d0316d7d7cf8d40fdcc1
```

Run the loader to retrieve the main script from the blockchain:
```bash
./scypherdload.sh
```

This will:
- Fetch the encoded script pieces from the blockchain
- Automatically decode and decompress them
- Create the scypher.sh file in your current directory
- Clean up any temporary files

The downloader ensures you always get the authentic, unmodified version of the script directly from the blockchain.

### Method 2: Traditional Installation
If you prefer the traditional method:

1. Clone the repository
2. Make the script executable:
```bash
chmod +x scypher.sh
```
3. Verify the script works:
```bash
./scypher.sh --help
```

## 💻 Usage

### Requirements
- Bash 4.0 or higher
- Basic POSIX utilities (read, printf, etc.)
- sha256sum command (usually part of coreutils)
- UTF-8 terminal support

### Examples
```bash
# To display the help message and all available options:
./scypher.sh --help
# or
./scypher.sh -h

# Basic interactive usage
./scypher.sh

# Save output to file (interactive mode)
./scypher.sh -f output_file

# Silent mode for script automation
./scypher.sh -s

# Debug mode
./scypher.sh -d
```

### Interactive Flow
1. Run the script
2. Enter seed phrase or input file path
3. Enter and confirm password
4. View results
5. Press enter to clear screen

## 🔒 Security

### Security Features
- Perfect Shuffle Algorithm: Implements an advanced shuffling mechanism for optimal statistical distribution
- Interactive Input: Secure input method for seed phrases and passwords
- Multiple Input Methods: Support for direct input or reading from files
- Password-Based Transformation: Uses password input to generate unique transformations
- Reversible Operations: Guarantees 100% accuracy in reversing transformations
- BIP39 Compliance: All output remains valid BIP39 words
- Cross-Platform Support: Works on Linux, macOS, and Windows (with bash)
- No External Dependencies: Uses only bash built-ins and core utilities
- Silent Mode: Available for script automation

### Security Strengths
- Statistical Uniformity: Demonstrated through extensive testing
- No Data Leakage: Secure handling of sensitive information
- Memory Safety: Proper cleanup of sensitive data
- Input Validation: Robust error checking and input sanitization
- Deterministic Operation: Same input always produces same output
- No Temporary Files: All operations performed in memory
- Screen Clearing: Sensitive information is cleared from display

### Security Analysis
Extensive testing using our Python Script Analyzer tool has shown:

Distribution Analysis:
- Uniform distribution across all word positions (Chi-square p-values > 0.05)
- No significant word frequency bias (max frequency ~1.5% in 10,000 tests)
- High entropy maintained across all positions

Reversibility Testing:
- 100% success rate in reversibility tests
- Perfect reconstruction of original seed phrases
- No data loss or corruption in transformation process

Test Results Summary:
- Total tests: 10,000
- Success rate: 100%
- Reversibility: 100%
- Chi-square p-values: 0.08-0.99 (all positions)
- Word frequency: Max 1.5% occurrence

### Security Considerations
While this tool has been thoroughly tested and analyzed, users should:
- Keep their passwords secure
- Not share transformed seed phrases
- Maintain secure backups of original seeds
- Test recovery process before use
- Verify script integrity before use

## 🛠 Technical Details

### Implementation Notes
- Uses Fisher-Yates shuffle with cryptographic seeding
- Implements perfect shuffle algorithm for optimal distribution
- Employs secure password handling mechanisms
- Includes comprehensive input validation

### Performance
- Linear time complexity O(n) for operations
- Constant memory usage
- No disk I/O beyond initial loading

## Script Analyzer
A Python-based analysis tool is included to verify the statistical properties and security characteristics of the cipher implementation.

### Analyzer Requirements
- Python 3.8 or higher
- Required Python packages:
  - numpy
  - pandas
  - scipy
  - tqdm
  - matplotlib
  - seaborn
  - psutil

### Analyzer Installation
Install the required packages using pip:

```bash
pip install numpy pandas scipy tqdm matplotlib seaborn psutil
```

### Analyzer Usage
Basic usage with default settings:

```bash
python script_analyzer.py                  # Run with defaults (English UI, random passwords, high resources)
```

Available options:

```bash
python script_analyzer.py -h               # Show help message with examples
python script_analyzer.py -r 1             # Resource usage (1=low, 2=med, 3=high)
python script_analyzer.py -p random        # Password mode (random/similar)
python script_analyzer.py -l en            # Language (en/es)
python script_analyzer.py -t 1000          # Number of tests
python script_analyzer.py -rv 500          # Number of reversibility tests
python script_analyzer.py -sp "word1 ..."  # Custom seed phrase for testing
```

Example with multiple options:

```bash
# Run 1000 tests with Spanish interface and custom seed phrase
python script_analyzer.py -t 1000 -l es -sp "word1 word2 word3 word4"

# Run analysis with default seed phrase and mid resources
python script_analyzer.py -r 2 -t 5000
```

Note: When using `-sp` (seed phrase), ensure all words are valid BIP39 words.

### Analyzer Output
The analyzer creates:
- JSON files with detailed analysis results in analysis_results/
- Statistical plots in analysis_results/plots/
- Console output with key metrics and findings
- Detailed terminal output saved to file

### Analysis Features
- Distribution analysis across word positions
- Chi-square tests for uniformity
- Entropy calculations
- Autocorrelation analysis
- Frequency distribution visualization
- Comprehensive reversibility testing
- Statistical anomaly detection
- Resource usage optimization
- Support for large-scale tests (10M+)
- Bilingual interface (English/Spanish)
- Custom seed phrase testing capabilities
- Position-based analysis (numbered 1-24)
- Detailed seed phrase information in reports

## 📜 Legal

### License
This project is released under the MIT License. You are free to:
- Use the software commercially
- Modify the source code
- Distribute the software
- Use it privately

### Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The developers assume no responsibility for:
- Loss of funds or assets
- Incorrect usage of the software
- Modifications made by third parties
- Security implications of usage in specific contexts

## 🤝 Contributing
Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests for any improvements. Please note that this project was developed with significant assistance from AI, and I am not a real developer.

Made with ❤️ for the Open Source Community
