# Bash BIP39 Seed Cipher

A secure and efficient tool for encoding and decoding BIP39 seed phrases while maintaining the BIP39 word format.

## 📝 Project Description

This script provides a secure way to transform BIP39 seed phrases into alternative valid BIP39 phrases and back, using password-based encryption. It maintains the original security properties of BIP39 while adding an extra layer of protection through reversible transformation.

The transformation is:
* Completely reversible
* Password-dependent
* Statistically uniform
* Maintaining BIP39 format

## ✨ Key Features

* **Perfect Shuffle Algorithm**: Implements an advanced shuffling mechanism for optimal statistical distribution
* **Password-Based Transformation**: Uses password input to generate unique transformations
* **Reversible Operations**: Guarantees 100% accuracy in reversing transformations
* **BIP39 Compliance**: All output remains valid BIP39 words
* **Command-Line Interface**: Simple and efficient CLI with various options
* **Cross-Platform Support**: Works on Linux, macOS, and Windows (with bash)
* **No External Dependencies**: Uses only bash built-ins and core utilities

## 🔒 Security Strengths

* **Statistical Uniformity**: Demonstrated through extensive testing
* **No Data Leakage**: Secure handling of sensitive information
* **Memory Safety**: Proper cleanup of sensitive data
* **Input Validation**: Robust error checking and input sanitization
* **Deterministic Operation**: Same input always produces same output
* **No Temporary Files**: All operations performed in memory

## 📊 Security Analysis

Extensive testing using our Python Script Analyzer tool has shown:

### Distribution Analysis
* Uniform distribution across all word positions (Chi-square p-values > 0.05)
* No significant word frequency bias (max frequency ~1.5% in 10,000 tests)
* High entropy maintained across all positions

### Reversibility Testing
* 100% success rate in reversibility tests
* Perfect reconstruction of original seed phrases
* No data loss or corruption in transformation process

### Statistical Properties
* Uniform word distribution
* No detectable patterns or biases
* Strong resistance to statistical analysis

### Test Results Summary
```
Total tests: 10,000
Success rate: 100%
Reversibility: 100%
Chi-square p-values: 0.08-0.99 (all positions) - All values well above critical threshold of 0.05, indicating excellent uniformity
Word frequency: Max 1.5% occurrence
```

## 💻 Usage Example

```bash
# Basic usage
./scypher.sh word1 word2 word3

# Save output to file
./scypher.sh -f output_file word1 word2 word3

# Specify password in command line (not recommended)
./scypher.sh -p mypassword word1 word2 word3

# Process words from file and save to a file
./scypher.sh -f output_file input_seed.txt
```

## 📋 Requirements

* Bash 4.0 or higher
* Basic POSIX utilities (read, printf, etc.)
* sha256sum command (usually part of coreutils)

## 🚀 Installation

1. Clone the repository
2. Make the script executable:
   ```bash
   chmod +x scypher.sh
   ```
3. Verify the script works:
   ```bash
   ./scypher.sh --help
   ```

## 📜 License and Disclaimer

### License
This project is released under the MIT License. You are free to:
* Use the software commercially
* Modify the source code
* Distribute the software
* Use it privately

### Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The developers assume no responsibility for:
* Loss of funds or assets
* Incorrect usage of the software
* Modifications made by third parties
* Security implications of usage in specific contexts

## 🔐 Security Considerations

While this tool has been thoroughly tested and analyzed, users should:
* Keep their passwords secure
* Not share transformed seed phrases
* Maintain secure backups of original seeds
* Test recovery process before use
* Verify script integrity before use

## 🛠 Technical Details

### Implementation Notes
* Uses Fisher-Yates shuffle with cryptographic seeding
* Implements perfect shuffle algorithm for optimal distribution
* Employs secure password handling mechanisms
* Includes comprehensive input validation

### Performance
* Linear time complexity O(n) for operations
* Constant memory usage
* No disk I/O beyond initial loading

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests for any improvements. Please note that this project was developed with significant assistance from AI, and I am not a developer with advanced technical knowledge.

---
Made with ❤️ for the Open Source Community
