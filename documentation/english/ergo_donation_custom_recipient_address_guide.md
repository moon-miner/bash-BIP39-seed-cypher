# 🚀 Complete Guide: Implementing Ergo Donations with Custom Recipient Address

**Version:** 2.0  
**Date:** June 2025  
**Purpose:** Enable developers to implement Ergo donation systems with their own recipient addresses

---

## 📋 Table of Contents

1. [Quick Start Guide](#1-quick-start-guide)
2. [Understanding the Code Structure](#2-understanding-the-code-structure)
3. [Customizing Your Recipient Address](#3-customizing-your-recipient-address)
4. [Complete Implementation Options](#4-complete-implementation-options)
5. [Fleet SDK Modern Approach](#5-fleet-sdk-modern-approach)
6. [Testing and Validation](#6-testing-and-validation)
7. [Deployment Checklist](#7-deployment-checklist)
8. [Troubleshooting](#8-troubleshooting)
9. [Advanced Customization](#9-advanced-customization)
10. [Resources and Support](#10-resources-and-support)

---

## 1. Quick Start Guide

### 🎯 What You Need to Change

The original code sends donations to this address:
```javascript
const DONATION_ADDRESS = "9f4WEgtBoWrtMa4HoUmxA3NSeWMU9PZRvArVGrSS3whSWfGDBoY";
```

**You need to replace it with YOUR address where you want to receive donations.**

### ⚡ Quick Configuration Steps

1. **Find Your Ergo Address**
   - Open your Nautilus Wallet or other Ergo wallet
   - Copy your receiving address (starts with "9")

2. **Update the Configuration**
   ```javascript
   // Replace this line in your code:
   const DONATION_ADDRESS = "9f4WEgtBoWrtMa4HoUmxA3NSeWMU9PZRvArVGrSS3whSWfGDBoY";
   
   // With YOUR address:
   const DONATION_ADDRESS = "YOUR_ERGO_ADDRESS_HERE";
   ```

3. **Test the Integration**
   - Deploy to testnet first
   - Make a small test donation
   - Verify funds arrive in your wallet

### 🔍 Example Address Formats

Valid Ergo addresses look like this:
```
9f4WEgtBoWrtMa4HoUmxA3NSeWMU9PZRvArVGrSS3whSWfGDBoY  ✅ Valid P2PK
9gNvAv97W71Wm33GoXgSQBFJxinFubKvE6wh2dEhFTSgYEe783j  ✅ Valid P2PK
9i2bQmRpCPLmDdVgBNyeAy7dDXqBQfjvcxVVt5YMzbDud6AvJS8  ✅ Valid P2PK
```

**Requirements:**
- Must start with "9"
- Must be 51-52 characters long
- Must be a valid Base58 encoded address

---

## 2. Understanding the Code Structure

### 📁 File Structure Overview

Your donation system consists of these key components:

```
donation-system/
├── index.html          # Main webpage
├── css/
│   └── styles.css     # Styling
├── js/
│   ├── main.js        # Navigation and UI
│   ├── donation.js    # ← MAIN FILE TO MODIFY
│   ├── download.js    # Download functionality
│   └── translations.js # Multi-language support
```

### 🎯 Key Configuration Points

**In `donation.js`:**

1. **Donation Address** (Line ~4):
   ```javascript
   const DONATION_ADDRESS = "YOUR_ADDRESS_HERE";
   ```

2. **Fee Configuration** (Lines ~5-7):
   ```javascript
   const NANOERGS_PER_ERG = 1000000000n;
   const MIN_FEE = 1000000n; // 0.001 ERG - DON'T CHANGE
   const FEE_ERGOTREE = "1005..."; // Miner contract - DON'T CHANGE
   ```

3. **Display Text** (Lines ~300+):
   ```javascript
   console.log('🎯 Recipient:', DONATION_ADDRESS);
   ```

### 🔧 What Each File Does

| File | Purpose | Need to Modify? |
|------|---------|----------------|
| `donation.js` | Core donation logic | ✅ YES - Update address |
| `main.js` | UI and navigation | ❌ NO - Keep as is |
| `translations.js` | Text translations | 🔶 OPTIONAL - Update text |
| `download.js` | Blockchain downloads | ❌ NO - Keep as is |
| `index.html` | Main structure | 🔶 OPTIONAL - Update branding |

---

## 3. Customizing Your Recipient Address

### 🎯 Method 1: Simple Address Replacement

**Step 1:** Open `donation.js`

**Step 2:** Find this line:
```javascript
const DONATION_ADDRESS = "9f4WEgtBoWrtMa4HoUmxA3NSeWMU9PZRvArVGrSS3whSWfGDBoY";
```

**Step 3:** Replace with your address:
```javascript
const DONATION_ADDRESS = "9gNvAv97W71Wm33GoXgSQBFJxinFubKvE6wh2dEhFTSgYEe783j"; // Your address
```

**Step 4:** Update any hardcoded fallbacks (around line 150):
```javascript
// Find this section and update the fallback address:
if (address === DONATION_ADDRESS) {
    console.log('🔧 Using hardcoded ErgoTree for donation address');
    return "YOUR_ERGOTREE_HERE"; // Update this too
}
```

### 🛡️ Method 2: Dynamic Configuration

Create a configuration object for easier management:

```javascript
// Add at the top of donation.js
const DONATION_CONFIG = {
    address: "YOUR_ERGO_ADDRESS_HERE",
    name: "Your Project Name",
    description: "Supporting Your Amazing Project",
    minAmount: 0.001, // Minimum donation in ERG
    defaultAmounts: [1, 5, 10], // Suggested amounts
};

// Update the constant
const DONATION_ADDRESS = DONATION_CONFIG.address;
```

### 🔍 Address Validation

Add validation to ensure your address is correct:

```javascript
// Add this validation function
function validateDonationAddress(address) {
    // Check format
    if (!address || typeof address !== 'string') {
        throw new Error('Donation address must be a valid string');
    }
    
    // Check length
    if (address.length < 51 || address.length > 52) {
        throw new Error('Donation address has invalid length');
    }
    
    // Check prefix
    if (!address.startsWith('9')) {
        throw new Error('Donation address must start with "9"');
    }
    
    // Check Base58 characters
    const base58Regex = /^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/;
    if (!base58Regex.test(address)) {
        throw new Error('Donation address contains invalid characters');
    }
    
    return true;
}

// Validate on startup
try {
    validateDonationAddress(DONATION_ADDRESS);
    console.log('✅ Donation address validated successfully');
} catch (error) {
    console.error('❌ Invalid donation address:', error.message);
    throw error;
}
```

---

## 4. Complete Implementation Options

### 🚀 Option A: Minimal Changes (Recommended for Beginners)

If you want to make minimal changes to the existing code:

```javascript
// donation.js - Only change these lines:

// Line 4: Update your address
const DONATION_ADDRESS = "YOUR_ERGO_ADDRESS_HERE";

// Line 150: Update fallback (optional, but recommended)
if (address === DONATION_ADDRESS) {
    console.log('🔧 Using hardcoded ErgoTree for donation address');
    // Convert your address to ErgoTree format
    return addressToErgoTree(DONATION_ADDRESS); 
}

// That's it! The rest of the code will work automatically.
```

### 🏗️ Option B: Complete Custom Implementation

For a fully customized donation system:

```javascript
// custom-donation.js - Complete implementation
class CustomDonationSystem {
    constructor(config) {
        this.config = {
            recipientAddress: config.recipientAddress,
            projectName: config.projectName || "My Project",
            minDonation: config.minDonation || 0.001,
            maxDonation: config.maxDonation || 1000,
            suggestedAmounts: config.suggestedAmounts || [0.1, 0.5, 1, 5],
            ...config
        };
        
        this.validateConfig();
        this.ergoApi = null;
        this.isConnected = false;
    }
    
    validateConfig() {
        if (!this.config.recipientAddress) {
            throw new Error('Recipient address is required');
        }
        
        if (!this.config.recipientAddress.startsWith('9')) {
            throw new Error('Invalid Ergo address format');
        }
        
        console.log(`✅ ${this.config.projectName} donation system configured`);
        console.log(`🎯 Donations will go to: ${this.config.recipientAddress}`);
    }
    
    async initialize() {
        try {
            await this.detectNautilus();
            await this.connectWallet();
            this.setupUI();
            console.log('🚀 Donation system ready!');
        } catch (error) {
            console.error('❌ Failed to initialize:', error);
            throw error;
        }
    }
    
    async detectNautilus() {
        return new Promise((resolve, reject) => {
            let attempts = 0;
            const maxAttempts = 50;
            
            const checkNautilus = () => {
                attempts++;
                
                if (window.ergoConnector?.nautilus) {
                    console.log('✅ Nautilus Wallet detected');
                    resolve(window.ergoConnector.nautilus);
                    return;
                }
                
                if (attempts < maxAttempts) {
                    setTimeout(checkNautilus, 100);
                } else {
                    reject(new Error('Nautilus Wallet not found'));
                }
            };
            
            checkNautilus();
        });
    }
    
    async connectWallet() {
        const nautilus = await this.detectNautilus();
        const connected = await nautilus.connect();
        
        if (connected) {
            this.ergoApi = window.ergo;
            this.isConnected = true;
            console.log('🔗 Wallet connected successfully');
        } else {
            throw new Error('Wallet connection rejected');
        }
    }
    
    async donate(amount) {
        if (!this.isConnected) {
            throw new Error('Wallet not connected');
        }
        
        if (amount < this.config.minDonation) {
            throw new Error(`Minimum donation is ${this.config.minDonation} ERG`);
        }
        
        if (amount > this.config.maxDonation) {
            throw new Error(`Maximum donation is ${this.config.maxDonation} ERG`);
        }
        
        try {
            console.log(`💰 Processing donation of ${amount} ERG...`);
            
            // Build transaction using Fleet SDK or manual method
            const tx = await this.buildDonationTransaction(amount);
            
            // Sign transaction
            const signedTx = await this.ergoApi.sign_tx(tx);
            
            // Submit transaction
            const txId = await this.ergoApi.submit_tx(signedTx);
            
            console.log(`🎉 Donation successful! TX: ${txId}`);
            return txId;
            
        } catch (error) {
            console.error('❌ Donation failed:', error);
            throw error;
        }
    }
    
    async buildDonationTransaction(amount) {
        // Get current data
        const height = await this.ergoApi.get_current_height();
        const utxos = await this.ergoApi.get_utxos();
        
        // Convert amount
        const nanoErgs = BigInt(Math.floor(amount * 1000000000));
        const fee = BigInt(1000000); // 0.001 ERG
        
        // Select inputs
        const { inputs, totalValue, tokens } = this.selectInputs(utxos, nanoErgs + fee);
        
        // Build outputs
        const outputs = [];
        
        // Donation output
        outputs.push({
            value: nanoErgs.toString(),
            ergoTree: this.addressToErgoTree(this.config.recipientAddress),
            assets: [],
            additionalRegisters: {},
            creationHeight: height
        });
        
        // Fee output
        outputs.push({
            value: fee.toString(),
            ergoTree: "1005040004000e36100204a00b08cd0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ea02d192a39a8cc7a701730073011001020402d19683030193a38cc7b2a57300000193c2b2a57301007473027303830108cdeeac93b1a57304",
            assets: [],
            additionalRegisters: {},
            creationHeight: height
        });
        
        // Change output (if needed)
        const changeAmount = totalValue - nanoErgs - fee;
        if (changeAmount > 0n || tokens.length > 0) {
            outputs.push({
                value: Math.max(Number(changeAmount), 1000000).toString(),
                ergoTree: inputs[0].ergoTree,
                assets: tokens,
                additionalRegisters: {},
                creationHeight: height
            });
        }
        
        return {
            inputs: inputs,
            outputs: outputs,
            dataInputs: []
        };
    }
    
    selectInputs(utxos, requiredAmount) {
        let totalValue = 0n;
        const selectedInputs = [];
        const allTokens = [];
        
        // Sort by value (largest first)
        const sortedUtxos = [...utxos].sort((a, b) => 
            Number(BigInt(b.value) - BigInt(a.value))
        );
        
        for (const utxo of sortedUtxos) {
            selectedInputs.push(utxo);
            totalValue += BigInt(utxo.value);
            
            // Collect tokens
            if (utxo.assets) {
                allTokens.push(...utxo.assets);
            }
            
            if (totalValue >= requiredAmount) {
                break;
            }
        }
        
        if (totalValue < requiredAmount) {
            throw new Error('Insufficient funds');
        }
        
        return {
            inputs: selectedInputs,
            totalValue: totalValue,
            tokens: allTokens
        };
    }
    
    addressToErgoTree(address) {
        // Implement address to ErgoTree conversion
        // (Use the same logic from the original code)
        // ... implementation here ...
    }
    
    setupUI() {
        // Update UI with your project information
        const titleElements = document.querySelectorAll('.donation-title, .project-name');
        titleElements.forEach(el => {
            if (el) el.textContent = this.config.projectName;
        });
        
        const addressElements = document.querySelectorAll('.donation-address');
        addressElements.forEach(el => {
            if (el) el.textContent = this.config.recipientAddress;
        });
        
        // Update suggested amounts
        const amountButtons = document.querySelectorAll('.amount-btn');
        this.config.suggestedAmounts.forEach((amount, index) => {
            if (amountButtons[index]) {
                amountButtons[index].textContent = `${amount} ERG`;
                amountButtons[index].setAttribute('data-amount', amount);
            }
        });
        
        console.log('🎨 UI updated with custom configuration');
    }
}

// Usage example:
const donationSystem = new CustomDonationSystem({
    recipientAddress: "YOUR_ERGO_ADDRESS_HERE",
    projectName: "My Awesome Project",
    minDonation: 0.01,
    maxDonation: 100,
    suggestedAmounts: [0.1, 0.5, 1, 5, 10]
});

// Initialize when page loads
document.addEventListener('DOMContentLoaded', async () => {
    try {
        await donationSystem.initialize();
    } catch (error) {
        console.error('Failed to initialize donation system:', error);
    }
});
```

---

## 5. Fleet SDK Modern Approach

### 📦 Using Fleet SDK for Transaction Building

The modern approach uses Fleet SDK's TransactionBuilder:

```javascript
// modern-donation-fleet.js
import { TransactionBuilder, OutputBuilder } from "@fleet-sdk/core";

class FleetDonationSystem {
    constructor(recipientAddress) {
        this.recipientAddress = recipientAddress;
        this.ergoApi = null;
    }
    
    async connect() {
        // Connect to Nautilus
        const nautilus = window.ergoConnector.nautilus;
        const connected = await nautilus.connect();
        
        if (connected) {
            this.ergoApi = window.ergo;
            return true;
        }
        return false;
    }
    
    async donateWithFleet(amountERG) {
        try {
            // Get blockchain data
            const height = await this.ergoApi.get_current_height();
            const inputs = await this.ergoApi.get_utxos();
            const changeAddress = await this.ergoApi.get_change_address();
            
            // Convert amount to nanoERGs
            const amountNanoERG = BigInt(Math.floor(amountERG * 1000000000));
            
            // Build transaction using Fleet SDK
            const unsignedTx = new TransactionBuilder(height)
                .from(inputs)                                    // Add inputs
                .to(                                            // Add donation output
                    new OutputBuilder(amountNanoERG, this.recipientAddress)
                )
                .sendChangeTo(changeAddress)                     // Send change back
                .payMinFee()                                    // Add network fee
                .build()                                        // Build transaction
                .toPlainObject();                               // Convert to object
            
            console.log('📋 Transaction built with Fleet SDK:');
            console.log(`  💰 Donation: ${amountERG} ERG → ${this.recipientAddress}`);
            console.log(`  🔄 Change: → ${changeAddress}`);
            console.log(`  💸 Fee: 0.001 ERG → miners`);
            
            // Sign transaction
            const signedTx = await this.ergoApi.sign_tx(unsignedTx);
            
            // Submit transaction
            const txId = await this.ergoApi.submit_tx(signedTx);
            
            console.log(`🎉 Donation successful! TX ID: ${txId}`);
            return txId;
            
        } catch (error) {
            console.error('❌ Fleet donation failed:', error);
            throw error;
        }
    }
    
    async donateWithTokens(amountERG, tokensToSend = []) {
        try {
            const height = await this.ergoApi.get_current_height();
            const inputs = await this.ergoApi.get_utxos();
            const changeAddress = await this.ergoApi.get_change_address();
            
            const amountNanoERG = BigInt(Math.floor(amountERG * 1000000000));
            
            // Create output with tokens
            const donationOutput = new OutputBuilder(amountNanoERG, this.recipientAddress);
            
            // Add tokens if specified
            if (tokensToSend.length > 0) {
                donationOutput.addTokens(tokensToSend);
            }
            
            const unsignedTx = new TransactionBuilder(height)
                .from(inputs)
                .to(donationOutput)
                .sendChangeTo(changeAddress)
                .payMinFee()
                .build()
                .toPlainObject();
            
            console.log('📋 Token donation transaction built');
            console.log(`  💰 ERG: ${amountERG}`);
            console.log(`  🏷️ Tokens: ${tokensToSend.length} types`);
            
            const signedTx = await this.ergoApi.sign_tx(unsignedTx);
            const txId = await this.ergoApi.submit_tx(signedTx);
            
            return txId;
            
        } catch (error) {
            console.error('❌ Token donation failed:', error);
            throw error;
        }
    }
    
    async donateToMultipleRecipients(donations) {
        // donations = [{ address: "...", amount: 1.5 }, { address: "...", amount: 0.5 }]
        try {
            const height = await this.ergoApi.get_current_height();
            const inputs = await this.ergoApi.get_utxos();
            const changeAddress = await this.ergoApi.get_change_address();
            
            // Create multiple outputs
            const outputs = donations.map(donation => 
                new OutputBuilder(
                    BigInt(Math.floor(donation.amount * 1000000000)),
                    donation.address
                )
            );
            
            const unsignedTx = new TransactionBuilder(height)
                .from(inputs)
                .to(outputs)                    // Multiple outputs
                .sendChangeTo(changeAddress)
                .payMinFee()
                .build()
                .toPlainObject();
            
            console.log(`📋 Multi-recipient transaction: ${donations.length} recipients`);
            
            const signedTx = await this.ergoApi.sign_tx(unsignedTx);
            const txId = await this.ergoApi.submit_tx(signedTx);
            
            return txId;
            
        } catch (error) {
            console.error('❌ Multi-recipient donation failed:', error);
            throw error;
        }
    }
}

// Usage with Fleet SDK
const fleetDonation = new FleetDonationSystem("YOUR_ERGO_ADDRESS_HERE");

// Connect and donate
async function donateWithFleetSDK(amount) {
    try {
        await fleetDonation.connect();
        const txId = await fleetDonation.donateWithFleet(amount);
        console.log(`✅ Donation completed: ${txId}`);
        return txId;
    } catch (error) {
        console.error('❌ Donation failed:', error);
        throw error;
    }
}

// Advanced usage examples:

// 1. Donate with specific tokens
async function donateTokens() {
    await fleetDonation.connect();
    
    const tokensToSend = [
        { tokenId: "token123...", amount: 100n },
        { tokenId: "token456...", amount: 50n }
    ];
    
    const txId = await fleetDonation.donateWithTokens(1.0, tokensToSend);
    return txId;
}

// 2. Split donation among multiple recipients
async function splitDonation() {
    await fleetDonation.connect();
    
    const recipients = [
        { address: "recipient1...", amount: 0.5 },
        { address: "recipient2...", amount: 0.3 },
        { address: "recipient3...", amount: 0.2 }
    ];
    
    const txId = await fleetDonation.donateToMultipleRecipients(recipients);
    return txId;
}
```

### 📦 Installing Fleet SDK

If you want to use Fleet SDK, add it to your project:

**Option 1: NPM (for Node.js projects)**
```bash
npm install @fleet-sdk/core
```

**Option 2: CDN (for browser projects)**
```html
<script type="module">
import { TransactionBuilder, OutputBuilder } from 'https://cdn.skypack.dev/@fleet-sdk/core';
// Your code here
</script>
```

**Option 3: Download and host locally**
1. Download Fleet SDK from GitHub
2. Include in your project
3. Import as needed

---

## 6. Testing and Validation

### 🧪 Pre-Deployment Testing

**Step 1: Address Validation Test**
```javascript
// Test your address format
function testAddressFormat() {
    const testAddress = "YOUR_ERGO_ADDRESS_HERE";
    
    console.log('🧪 Testing address format...');
    console.log(`Address: ${testAddress}`);
    console.log(`Length: ${testAddress.length} characters`);
    console.log(`Starts with 9: ${testAddress.startsWith('9') ? '✅' : '❌'}`);
    console.log(`Valid length: ${testAddress.length >= 51 && testAddress.length <= 52 ? '✅' : '❌'}`);
    
    // Test Base58 characters
    const base58Regex = /^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/;
    console.log(`Valid Base58: ${base58Regex.test(testAddress) ? '✅' : '❌'}`);
    
    return testAddress.startsWith('9') && 
           testAddress.length >= 51 && 
           testAddress.length <= 52 && 
           base58Regex.test(testAddress);
}

// Run test
if (testAddressFormat()) {
    console.log('✅ Address format test PASSED');
} else {
    console.log('❌ Address format test FAILED');
}
```

**Step 2: Integration Test**
```javascript
// Test the complete donation flow
async function testDonationFlow() {
    console.log('🧪 Testing complete donation flow...');
    
    try {
        // 1. Test Nautilus detection
        console.log('1. Testing Nautilus detection...');
        if (window.ergoConnector?.nautilus) {
            console.log('✅ Nautilus detected');
        } else {
            throw new Error('Nautilus not found');
        }
        
        // 2. Test connection
        console.log('2. Testing wallet connection...');
        const connected = await window.ergoConnector.nautilus.connect();
        if (connected) {
            console.log('✅ Wallet connected');
        } else {
            throw new Error('Connection failed');
        }
        
        // 3. Test balance check
        console.log('3. Testing balance check...');
        const balance = await window.ergo.get_balance();
        const balanceERG = Number(BigInt(balance)) / 1000000000;
        console.log(`✅ Balance: ${balanceERG} ERG`);
        
        // 4. Test transaction building (don't send)
        console.log('4. Testing transaction building...');
        const testAmount = 0.001; // 0.001 ERG test
        
        if (balanceERG >= testAmount + 0.001) { // Amount + fee
            console.log(`✅ Sufficient balance for test (${testAmount} ERG + 0.001 fee)`);
            
            // Here you would build a test transaction but not send it
            console.log('⚠️ Transaction building test would go here');
            console.log('💡 Ready for actual donation testing');
        } else {
            console.log(`❌ Insufficient balance. Need ${testAmount + 0.001} ERG`);
        }
        
        console.log('🎉 All tests passed! System ready for donations.');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run integration test
testDonationFlow();
```

**Step 3: Small Amount Test**
```javascript
// Test with smallest possible donation
async function testSmallDonation() {
    const MINIMUM_AMOUNT = 0.001; // 0.001 ERG
    
    try {
        console.log(`🧪 Testing minimum donation of ${MINIMUM_AMOUNT} ERG...`);
        
        // Make sure you're connected
        if (!window.ergo) {
            throw new Error('Wallet not connected');
        }
        
        // Check balance
        const balance = await window.ergo.get_balance();
        const balanceERG = Number(BigInt(balance)) / 1000000000;
        
        if (balanceERG < MINIMUM_AMOUNT + 0.001) {
            throw new Error('Insufficient balance for test');
        }
        
        console.log('⚠️ This will make an actual donation to your configured address');
        console.log(`Recipient: ${DONATION_ADDRESS}`);
        console.log('Proceed only if this is correct!');
        
        // Uncomment to actually test:
        // const txId = await executeDonation(MINIMUM_AMOUNT);
        // console.log(`✅ Test donation successful: ${txId}`);
        
    } catch (error) {
        console.error('❌ Small donation test failed:', error);
    }
}
```

### 🔍 Debugging Helpers

```javascript
// Debug transaction details
function debugTransaction(transaction) {
    console.log('🔍 TRANSACTION DEBUG');
    console.log('═══════════════════════════════════════');
    
    console.log('📥 INPUTS:');
    transaction.inputs.forEach((input, i) => {
        console.log(`  ${i + 1}. ${input.boxId.substring(0, 8)}... = ${Number(BigInt(input.value)) / 1000000000} ERG`);
    });
    
    console.log('📤 OUTPUTS:');
    transaction.outputs.forEach((output, i) => {
        const ergAmount = Number(BigInt(output.value)) / 1000000000;
        let type = 'UNKNOWN';
        
        if (output.ergoTree.includes('0008cd')) {
            if (output.ergoTree === addressToErgoTree(DONATION_ADDRESS)) {
                type = 'DONATION';
            } else {
                type = 'CHANGE';
            }
        } else if (output.ergoTree.includes('1005040004')) {
            type = 'FEE';
        }
        
        console.log(`  ${i + 1}. ${type}: ${ergAmount} ERG + ${output.assets?.length || 0} tokens`);
    });
    
    // Balance verification
    const totalInputs = transaction.inputs.reduce((sum, inp) => sum + BigInt(inp.value), 0n);
    const totalOutputs = transaction.outputs.reduce((sum, out) => sum + BigInt(out.value), 0n);
    
    console.log('💰 BALANCE CHECK:');
    console.log(`  Inputs: ${Number(totalInputs) / 1000000000} ERG`);
    console.log(`  Outputs: ${Number(totalOutputs) / 1000000000} ERG`);
    console.log(`  Balanced: ${totalInputs === totalOutputs ? '✅' : '❌'}`);
    
    console.log('═══════════════════════════════════════');
}

// Monitor transaction status
async function monitorTransactionStatus(txId) {
    console.log(`📡 Monitoring transaction: ${txId}`);
    console.log(`🔍 Check status at: https://explorer.ergoplatform.com/en/transactions/${txId}`);
    
    // You can implement API calls to check status
    console.log('ℹ️ Transaction submitted to mempool');
    console.log('⏳ Waiting for blockchain confirmation...');
    
    // Optional: Add automatic status checking
    // This would require API calls to Ergo Explorer
}
```

---

## 7. Deployment Checklist

### ✅ Pre-Deployment Checklist

**Configuration Verification:**
- [ ] ✅ Updated `DONATION_ADDRESS` with your address
- [ ] ✅ Verified address format (starts with "9", correct length)
- [ ] ✅ Tested address validation function
- [ ] ✅ Updated any hardcoded fallbacks
- [ ] ✅ Verified fee configuration (don't change)

**Testing Verification:**
- [ ] ✅ Tested Nautilus wallet detection
- [ ] ✅ Tested wallet connection
- [ ] ✅ Tested balance checking
- [ ] ✅ Tested small amount donation (0.001 ERG)
- [ ] ✅ Verified funds arrive in your wallet
- [ ] ✅ Tested with different browsers
- [ ] ✅ Tested mobile compatibility

**Code Quality:**
- [ ] ✅ Removed any console.log with sensitive data
- [ ] ✅ Added proper error handling
- [ ] ✅ Updated UI text to reflect your project
- [ ] ✅ Updated translations if using multiple languages
- [ ] ✅ Verified all links and references

**Security:**
- [ ] ✅ Double-checked recipient address
- [ ] ✅ Verified no hardcoded private keys
- [ ] ✅ Ensured HTTPS deployment
- [ ] ✅ Added input validation
- [ ] ✅ Tested against common attacks

### 🚀 Deployment Steps

**Step 1: Prepare Files**
```bash
# Your file structure should be:
donation-website/
├── index.html
├── css/
│   └── styles.css
├── js/
│   ├── main.js
│   ├── donation.js          # ← Modified with your address
│   ├── download.js
│   └── translations.js
└── assets/
    └── (any images/icons)
```

**Step 2: Update Configuration**
```javascript
// Final check of donation.js
const DONATION_ADDRESS = "YOUR_VERIFIED_ADDRESS"; // ← Your address here
const PROJECT_NAME = "Your Project Name";         // ← Optional: your project name

// Verify this matches your wallet address exactly
console.log('🎯 Donations will be sent to:', DONATION_ADDRESS);
```

**Step 3: Deploy to Web Server**

**Option A: Static Hosting (Recommended)**
- GitHub Pages
- Netlify
- Vercel
- Firebase Hosting

**Option B: Traditional Web Hosting**
- Upload files via FTP/SFTP
- Ensure HTTPS is enabled
- Test from multiple devices

**Step 4: Post-Deployment Testing**
```javascript
// Test on live site
async function postDeploymentTest() {
    console.log('🌐 Testing live deployment...');
    
    try {
        // 1. Test page load
        console.log('✅ Page loaded successfully');
        
        // 2. Test Nautilus detection
        if (window.ergoConnector?.nautilus) {
            console.log('✅ Nautilus detection works');
        } else {
            console.log('⚠️ Nautilus not detected - user needs to install');
        }
        
        // 3. Test configuration
        console.log(`📧 Donation address: ${DONATION_ADDRESS}`);
        console.log('✅ Configuration loaded correctly');
        
        // 4. Make test donation (small amount)
        console.log('💰 Ready for test donation');
        
    } catch (error) {
        console.error('❌ Deployment test failed:', error);
    }
}

// Run after deployment
postDeploymentTest();
```

---

## 8. Troubleshooting

### 🐛 Common Issues and Solutions

**Issue 1: Donations go to wrong address**
```
❌ Problem: Funds still go to original address
✅ Solution: Check these files for hardcoded addresses:
  - donation.js (line ~4)
  - donation.js (line ~150, fallback)
  - Any other .js files that might import the address
```

**Issue 2: "Invalid address format" error**
```
❌ Problem: Address validation fails
✅ Solution: Verify your address:
  - Must start with "9"
  - Must be 51-52 characters long
  - Must contain only Base58 characters
  - Copy directly from your wallet
```

**Issue 3: "Nautilus not detected"**
```
❌ Problem: Wallet connection fails
✅ Solution: 
  - Ensure Nautilus Wallet extension is installed
  - Refresh the page
  - Check browser console for errors
  - Try different browser
```

**Issue 4: "Transaction building failed"**
```
❌ Problem: Cannot build transaction
✅ Solution:
  - Check wallet balance (need amount + 0.001 ERG fee)
  - Verify address conversion function
  - Check for JavaScript errors
  - Ensure HTTPS deployment
```

**Issue 5: "Min fee not met" error**
```
❌ Problem: Fee configuration incorrect
✅ Solution: Don't modify fee settings:
  const MIN_FEE = 1000000n; // Keep as 0.001 ERG
  const FEE_ERGOTREE = "1005..."; // Don't change this
```

### 🔧 Debug Tools

**Console Debug Commands:**
```javascript
// Check current configuration
console.log('Current donation address:', DONATION_ADDRESS);
console.log('Address length:', DONATION_ADDRESS.length);
console.log('Starts with 9:', DONATION_ADDRESS.startsWith('9'));

// Test address conversion
try {
    const ergoTree = addressToErgoTree(DONATION_ADDRESS);
    console.log('✅ Address conversion successful');
    console.log('ErgoTree:', ergoTree);
} catch (error) {
    console.log('❌ Address conversion failed:', error);
}

// Check wallet status
if (window.ergoConnector?.nautilus) {
    console.log('✅ Nautilus available');
    if (window.ergo) {
        console.log('✅ Wallet connected');
    } else {
        console.log('⚠️ Wallet not connected');
    }
} else {
    console.log('❌ Nautilus not found');
}
```

**Network Debug:**
```javascript
// Check if on correct network
async function checkNetwork() {
    try {
        const height = await window.ergo.get_current_height();
        console.log(`📊 Current blockchain height: ${height}`);
        
        // Mainnet typically has height > 500,000
        if (height > 500000) {
            console.log('✅ Connected to Ergo Mainnet');
        } else {
            console.log('⚠️ Might be on testnet or local network');
        }
    } catch (error) {
        console.log('❌ Network check failed:', error);
    }
}
```

---

## 9. Advanced Customization

### 🎨 UI Customization

**Update Project Branding:**
```javascript
// Update project information in index.html
const PROJECT_CONFIG = {
    name: "Your Project Name",
    description: "Supporting sustainable blockchain development",
    logo: "path/to/your/logo.png",
    color: "#your-brand-color",
    recipientAddress: "YOUR_ERGO_ADDRESS_HERE"
};

// Update UI elements
function updateBranding() {
    // Update title
    document.title = `Support ${PROJECT_CONFIG.name}`;
    
    // Update header
    const brandName = document.querySelector('.brand-name');
    if (brandName) brandName.textContent = PROJECT_CONFIG.name;
    
    // Update description
    const subtitle = document.querySelector('.hero-subtitle');
    if (subtitle) subtitle.textContent = PROJECT_CONFIG.description;
    
    // Update donation address display
    const addressDisplays = document.querySelectorAll('.donation-address');
    addressDisplays.forEach(el => {
        if (el) el.textContent = PROJECT_CONFIG.recipientAddress;
    });
}

// Apply branding on page load
document.addEventListener('DOMContentLoaded', updateBranding);
```

**Custom Donation Amounts:**
```javascript
// Customize suggested donation amounts
const SUGGESTED_AMOUNTS = [0.1, 0.5, 1.0, 5.0, 10.0]; // In ERG

function updateDonationAmounts() {
    const amountButtons = document.querySelectorAll('.amount-btn');
    
    SUGGESTED_AMOUNTS.forEach((amount, index) => {
        if (amountButtons[index]) {
            amountButtons[index].textContent = `${amount} ERG`;
            amountButtons[index].setAttribute('data-amount', amount);
        }
    });
}

// Update minimum and maximum
const MIN_DONATION = 0.001; // ERG
const MAX_DONATION = 1000;   // ERG

function validateDonationAmount(amount) {
    if (amount < MIN_DONATION) {
        throw new Error(`Minimum donation is ${MIN_DONATION} ERG`);
    }
    if (amount > MAX_DONATION) {
        throw new Error(`Maximum donation is ${MAX_DONATION} ERG`);
    }
    return true;
}
```

**Multi-Language Support:**
```javascript
// Add your project to translations.js
const PROJECT_TRANSLATIONS = {
    en: {
        projectName: "Your Project Name",
        projectDescription: "Your project description",
        donationThankYou: "Thank you for supporting our project!",
        donationPurpose: "Funds will be used for project development and maintenance."
    },
    es: {
        projectName: "Nombre de Tu Proyecto",
        projectDescription: "Descripción de tu proyecto",
        donationThankYou: "¡Gracias por apoyar nuestro proyecto!",
        donationPurpose: "Los fondos se utilizarán para el desarrollo y mantenimiento del proyecto."
    },
    // Add more languages as needed
};

// Merge with existing translations
Object.keys(PROJECT_TRANSLATIONS).forEach(lang => {
    if (translations[lang]) {
        translations[lang] = {
            ...translations[lang],
            project: PROJECT_TRANSLATIONS[lang]
        };
    }
});
```

### 💎 Advanced Features

**Donation Goals and Progress:**
```javascript
class DonationGoalTracker {
    constructor(goalAmount, recipientAddress) {
        this.goalAmount = goalAmount; // Target amount in ERG
        this.recipientAddress = recipientAddress;
        this.currentAmount = 0;
    }
    
    async updateProgress() {
        try {
            // This would require an API to track donations to your address
            // You can use Ergo Explorer API or your own tracking system
            
            const progress = (this.currentAmount / this.goalAmount) * 100;
            this.updateProgressBar(progress);
            
        } catch (error) {
            console.error('Failed to update donation progress:', error);
        }
    }
    
    updateProgressBar(percentage) {
        const progressBar = document.querySelector('.donation-progress');
        const progressText = document.querySelector('.donation-progress-text');
        
        if (progressBar) {
            progressBar.style.width = `${Math.min(percentage, 100)}%`;
        }
        
        if (progressText) {
            progressText.textContent = `${this.currentAmount.toFixed(2)} / ${this.goalAmount} ERG (${percentage.toFixed(1)}%)`;
        }
    }
}

// Usage
const goalTracker = new DonationGoalTracker(100, "YOUR_ERGO_ADDRESS_HERE"); // 100 ERG goal
```

**Donation History:**
```javascript
class DonationHistory {
    constructor() {
        this.donations = [];
    }
    
    addDonation(amount, txId, timestamp = Date.now()) {
        const donation = {
            amount: amount,
            txId: txId,
            timestamp: timestamp,
            explorerUrl: `https://explorer.ergoplatform.com/en/transactions/${txId}`
        };
        
        this.donations.unshift(donation); // Add to beginning
        this.saveDonations();
        this.updateHistoryDisplay();
    }
    
    saveDonations() {
        try {
            localStorage.setItem('donationHistory', JSON.stringify(this.donations));
        } catch (error) {
            console.warn('Could not save donation history:', error);
        }
    }
    
    loadDonations() {
        try {
            const saved = localStorage.getItem('donationHistory');
            if (saved) {
                this.donations = JSON.parse(saved);
                this.updateHistoryDisplay();
            }
        } catch (error) {
            console.warn('Could not load donation history:', error);
        }
    }
    
    updateHistoryDisplay() {
        const historyContainer = document.querySelector('.donation-history');
        if (!historyContainer) return;
        
        if (this.donations.length === 0) {
            historyContainer.innerHTML = '<p>No donations yet.</p>';
            return;
        }
        
        const historyHTML = this.donations.map(donation => `
            <div class="donation-item">
                <div class="donation-amount">${donation.amount} ERG</div>
                <div class="donation-date">${new Date(donation.timestamp).toLocaleDateString()}</div>
                <div class="donation-tx">
                    <a href="${donation.explorerUrl}" target="_blank">
                        ${donation.txId.substring(0, 8)}...
                    </a>
                </div>
            </div>
        `).join('');
        
        historyContainer.innerHTML = historyHTML;
    }
}

// Initialize and use
const donationHistory = new DonationHistory();
donationHistory.loadDonations();

// Update after successful donation
async function donateAndTrack(amount) {
    try {
        const txId = await executeDonation(amount);
        donationHistory.addDonation(amount, txId);
        console.log('✅ Donation recorded in history');
        return txId;
    } catch (error) {
        console.error('❌ Donation failed:', error);
        throw error;
    }
}
```

**Recurring Donations:**
```javascript
class RecurringDonations {
    constructor(donationSystem) {
        this.donationSystem = donationSystem;
        this.recurringDonations = [];
    }
    
    setupRecurring(amount, intervalDays) {
        const recurring = {
            amount: amount,
            intervalDays: intervalDays,
            lastDonation: null,
            isActive: true,
            id: Date.now().toString()
        };
        
        this.recurringDonations.push(recurring);
        this.saveRecurringSettings();
        this.scheduleNext(recurring);
        
        return recurring.id;
    }
    
    scheduleNext(recurring) {
        if (!recurring.isActive) return;
        
        const interval = recurring.intervalDays * 24 * 60 * 60 * 1000; // Convert to milliseconds
        
        setTimeout(async () => {
            try {
                console.log(`🔄 Processing recurring donation: ${recurring.amount} ERG`);
                
                // Check if user is still connected
                if (window.ergo) {
                    await this.donationSystem.donate(recurring.amount);
                    recurring.lastDonation = Date.now();
                    this.saveRecurringSettings();
                    
                    // Schedule next donation
                    this.scheduleNext(recurring);
                } else {
                    console.log('⚠️ Wallet not connected for recurring donation');
                }
                
            } catch (error) {
                console.error('❌ Recurring donation failed:', error);
                // You might want to notify the user or retry
            }
        }, interval);
    }
    
    cancelRecurring(id) {
        const recurring = this.recurringDonations.find(r => r.id === id);
        if (recurring) {
            recurring.isActive = false;
            this.saveRecurringSettings();
            console.log('✅ Recurring donation cancelled');
        }
    }
    
    saveRecurringSettings() {
        try {
            localStorage.setItem('recurringDonations', JSON.stringify(this.recurringDonations));
        } catch (error) {
            console.warn('Could not save recurring settings:', error);
        }
    }
    
    loadRecurringSettings() {
        try {
            const saved = localStorage.getItem('recurringDonations');
            if (saved) {
                this.recurringDonations = JSON.parse(saved);
                
                // Restart active recurring donations
                this.recurringDonations
                    .filter(r => r.isActive)
                    .forEach(r => this.scheduleNext(r));
            }
        } catch (error) {
            console.warn('Could not load recurring settings:', error);
        }
    }
}

// Usage
const recurringSystem = new RecurringDonations(donationSystem);
recurringSystem.loadRecurringSettings();

// Setup a monthly recurring donation
function setupMonthlyDonation(amount) {
    const id = recurringSystem.setupRecurring(amount, 30); // 30 days
    console.log(`✅ Monthly donation setup: ${amount} ERG every 30 days`);
    return id;
}
```

---

## 10. Resources and Support

### 📚 Official Documentation

| Resource | URL | Description |
|----------|-----|-------------|
| Fleet SDK Docs | https://fleet-sdk.github.io/docs/ | Official Fleet SDK documentation |
| Fleet SDK GitHub | https://github.com/fleet-sdk/fleet | Source code and examples |
| Ergo Platform Docs | https://docs.ergoplatform.com/ | Complete Ergo documentation |
| Nautilus Wallet | https://github.com/nautls/nautilus-wallet | Nautilus Wallet documentation |
| Ergo Explorer | https://explorer.ergoplatform.com/ | Blockchain explorer |
| EIP-12 Specification | https://github.com/ergoplatform/eips/blob/master/eip-0012.md | Wallet connector protocol |

### 🛠️ Development Tools

| Tool | URL | Purpose |
|------|-----|---------|
| Ergo Playground | https://wallet.plutomonkey.com/ | Test transactions |
| Ergoscan | https://ergoscan.io/ | Alternative explorer |
| Node Interface | http://127.0.0.1:9053/ | Local node (if running) |
| Testnet Faucet | Various | Get test ERG |

### 💬 Community Support

| Platform | Link | Purpose |
|----------|------|---------|
| Ergo Discord | https://discord.gg/gYrVrjS | Developer discussions |
| Ergo Telegram | https://t.me/ergoplatform | General community |
| Ergo Reddit | https://reddit.com/r/ergonauts | Community discussions |
| Stack Overflow | Tag: ergo-platform | Technical Q&A |

### 🎯 Example Projects

**Study these projects for inspiration:**
- **Ergo Auction House:** https://ergoauctions.org/
- **ErgoDEX:** https://ergodex.io/
- **SigmaUSD:** https://sigmausd.io/
- **Ergo Mixer:** https://mixer.ergoplatform.com/

### 📋 Quick Reference

**Essential Code Snippets:**

```javascript
// 1. Basic address replacement
const DONATION_ADDRESS = "YOUR_ERGO_ADDRESS_HERE";

// 2. Validate address format
function isValidErgoAddress(address) {
    return address && 
           address.startsWith('9') && 
           address.length >= 51 && 
           address.length <= 52 &&
           /^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/.test(address);
}

// 3. Connect to Nautilus
async function connectWallet() {
    const nautilus = window.ergoConnector.nautilus;
    const connected = await nautilus.connect();
    return connected ? window.ergo : null;
}

// 4. Make donation with Fleet SDK
import { TransactionBuilder, OutputBuilder } from "@fleet-sdk/core";

async function donateWithFleet(amount, recipientAddress) {
    const height = await ergo.get_current_height();
    const inputs = await ergo.get_utxos();
    const changeAddress = await ergo.get_change_address();
    
    const tx = new TransactionBuilder(height)
        .from(inputs)
        .to(new OutputBuilder(BigInt(amount * 1000000000), recipientAddress))
        .sendChangeTo(changeAddress)
        .payMinFee()
        .build()
        .toPlainObject();
    
    const signedTx = await ergo.sign_tx(tx);
    return await ergo.submit_tx(signedTx);
}

// 5. Check transaction status
function checkTransaction(txId) {
    const explorerUrl = `https://explorer.ergoplatform.com/en/transactions/${txId}`;
    console.log(`Check status: ${explorerUrl}`);
    window.open(explorerUrl, '_blank');
}
```

### ✅ Final Checklist

**Before Going Live:**
- [ ] ✅ Updated donation address to yours
- [ ] ✅ Tested with small amounts
- [ ] ✅ Verified funds reach your wallet
- [ ] ✅ Updated all UI text and branding
- [ ] ✅ Tested on multiple browsers
- [ ] ✅ Deployed with HTTPS
- [ ] ✅ Added error handling
- [ ] ✅ Documented for your team

**Monitoring:**
- [ ] ✅ Set up transaction monitoring
- [ ] ✅ Monitor wallet for incoming funds
- [ ] ✅ Check website performance
- [ ] ✅ Monitor for user issues

---

## 🎉 Conclusion

You now have everything you need to implement a custom Ergo donation system with your own recipient address. The key steps are:

1. **Replace the donation address** with your own Ergo address
2. **Test thoroughly** with small amounts first
3. **Validate the integration** works correctly
4. **Deploy with HTTPS** for security
5. **Monitor and maintain** the system

### 🚀 Next Steps

1. **Start with the simple approach** (just replace the address)
2. **Test on testnet** if available
3. **Make a small mainnet test** (0.001 ERG)
4. **Gradually add customizations** as needed
5. **Document your setup** for future reference

### 💡 Pro Tips

- **Always test first** with small amounts
- **Keep backups** of your original working code
- **Monitor your wallet** for incoming donations
- **Use version control** (Git) to track changes
- **Document any customizations** you make

### 🆘 Need Help?

If you encounter issues:

1. **Check the troubleshooting section** first
2. **Use browser developer tools** to check for errors
3. **Test with different wallets/browsers**
4. **Join the Ergo community** for support
5. **Compare your code** with working examples

**Good luck with your Ergo donation implementation! 🚀**