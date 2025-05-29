# SCypher v2.0
## XOR-based BIP39 Seed Cipher

![Version](https://img.shields.io/badge/version-2.0--ErgoHack--X-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Bash](https://img.shields.io/badge/bash-4.0%2B-orange)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)

**A secure and reversible XOR-based cipher for BIP39 seed phrases that maintains complete BIP39 compatibility.**

🌐 **[Try it online](https://scypher.vercel.app/)** | 📥 **[Download](#installation)** | 📖 **[Documentation](#how-it-works)**

---

## 🎯 What is SCypher?

SCypher is a cryptographic tool that transforms BIP39 seed phrases into different valid BIP39 phrases using XOR encryption with SHAKE-256. The transformation is completely reversible - using the same password will restore your original seed phrase.

**Key Innovation**: Unlike traditional encryption that produces random data, SCypher maintains BIP39 format compliance, so the encrypted output is always a valid seed phrase that any BIP39-compatible wallet would accept.

### 🆚 Version 2.0 Improvements (ErgoHack X Release)
- **XOR-based encryption** (replacing the shuffle algorithm from v1.0)
- **SHAKE-256 keystream generation** for cryptographic security
- **Enhanced user interface** with interactive menus
- **Improved checksum handling** for perfect BIP39 compliance
- **No salt required** - purely deterministic transformation

---

## ✨ Features

- 🔒 **XOR Encryption**: Cryptographically secure with SHAKE-256 keystream
- 🎯 **BIP39 Compliant**: Output is always a valid BIP39 seed phrase
- 🔄 **Perfectly Reversible**: Same password restores original phrase
- 🚫 **No External Dependencies**: Pure Bash + OpenSSL implementation
- 🛡️ **Memory Secure**: Automatic cleanup of sensitive data
- 🖥️ **Cross-Platform**: Works on Linux, macOS, and Windows (WSL)
- 📱 **Multiple Input Methods**: Interactive, file input, or command line
- 🎨 **User-Friendly Interface**: Clear menus and visual feedback

---

## 🚀 Installation

### Method 1: Web Download (Easiest)
Visit **[scypher.vercel.app](https://scypher.vercel.app/)** and download directly from your browser. The website fetches the script from blockchain storage and provides the compressed file.

### Method 2: Blockchain CLI Download (Recommended)
Download the blockchain loader and fetch the script directly from decentralized storage:

```bash
# Get the loader script from blockchain
curl -X GET "https://api.sigmaspace.io/api/v1/tokens/b1715708cdc9c9f42f7de433061711b2ad79814a2e837e6aa9dd9de16b82d9d4" | jq -r '.description' | base64 -d > scypherdload.sh

# Make it executable
chmod +x scypherdload.sh

# Run the loader to download and extract SCypher
./scypherdload.sh

# Make SCypher executable
chmod +x SCypherV2.sh
```

### Method 3: Traditional GitHub
```bash
# Clone this repository
git clone https://github.com/moon-miner/bash-BIP39-seed-cypher.git
cd bash-BIP39-seed-cypher

# Make executable
chmod +x SCypherV2.sh
```

---

## 💻 Usage

### Basic Interactive Mode
```bash
./SCypherV2.sh
```
This opens the interactive menu where you can encrypt/decrypt seed phrases step by step.

### Command Line Options
```bash
./SCypherV2.sh -h                    # Show help
./SCypherV2.sh --license             # View license and disclaimer
./SCypherV2.sh --details             # Learn how the cipher works
./SCypherV2.sh -f output.txt         # Save result to file
./SCypherV2.sh -s < input.txt        # Silent mode for scripting
```

### Quick Example
1. Run `./SCypherV2.sh`
2. Enter your 12-24 word BIP39 seed phrase
3. Create a strong password
4. Choose number of iterations (more = more secure, slower)
5. Get your encrypted seed phrase (also valid BIP39)
6. To decrypt: repeat with same password and iterations

---

## 🔐 How It Works

SCypher v2.0 uses **XOR encryption** with a cryptographically secure keystream:

1. **Input Processing**: Your seed phrase is converted to binary (11 bits per word)
2. **Keystream Generation**: SHAKE-256 generates a keystream from your password
3. **XOR Operation**: Binary seed ⊕ keystream = encrypted binary
4. **Checksum Recalculation**: Ensures output remains BIP39-compliant
5. **Output**: Encrypted binary converted back to valid BIP39 words

**Decryption** is identical: encrypted phrase ⊕ same keystream = original phrase

### Security Properties
- **Information-theoretic security** when keystream length equals message length
- **Deterministic**: Same input + password always produces same output
- **No patterns**: Encrypted output appears statistically random
- **Perfect reversibility**: Zero data loss in transformation

---

## 🛡️ Security Recommendations

⚠️ **Important Security Notes:**

- **Use on clean, offline systems** when possible
- **Use strong, unique passwords** (8+ characters recommended)
- **Keep secure backups** of original seed phrases
- **Test recovery process** before relying on encrypted phrases
- **Never share** your encrypted phrases publicly
- **Verify** script integrity before use

### Sudo Usage Notice
The script may recommend running with `sudo` but **this is not required**. All core functionality works without root privileges. The sudo prompts are legacy code that will be removed in v3.0.

---

## 📋 Requirements

- **Bash 4.0+** (for associative arrays)
- **OpenSSL 3.0+** (for SHAKE-256 support)
- **Basic POSIX utilities**
- **UTF-8 terminal support**
- **100MB+ available RAM**

### Installation Check
Most systems have these by default. To verify:
```bash
bash --version    # Should be 4.0+
openssl version   # Should be 3.0+
```

---

## 🏆 ErgoHack X Competition

This release was developed for the **ErgoHack X** competition, featuring:
- Complete algorithm redesign from shuffle-based to XOR-based encryption
- Enhanced cryptographic security with SHAKE-256
- Improved user experience with interactive menus
- Better error handling and input validation

---

## 📜 Legal

### License
MIT License - You are free to use, modify, and distribute this software.

### Disclaimer
**THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.**

The developers assume no responsibility for:
- Loss of funds or cryptocurrency assets
- Incorrect usage or user errors
- Security implications in specific contexts
- Modifications made by third parties

**Always test with small amounts first and maintain secure backups.**

---

## 🤝 Contributing

Contributions welcome! This project was developed with AI assistance for the ErgoHack X competition. 

- 🐛 **Report bugs** via GitHub Issues
- 💡 **Suggest features** for future versions
- 🔧 **Submit pull requests** for improvements
- ⭐ **Star the repo** if you find it useful

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/moon-miner/bash-BIP39-seed-cypher/issues)
- **Website**: [scypher.vercel.app](https://scypher.vercel.app/)
- **Version**: 2.0-ErgoHack-X

---

*Made with ❤️ for the cryptocurrency community*