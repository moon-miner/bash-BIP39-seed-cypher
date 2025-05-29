# SCypher v2.0 - ELI5 Quick Guide
## Simple Seed Phrase Encryption Tool

🔐 **What is SCypher?**  
SCypher is like a secret code translator for your crypto wallet seed phrases. It takes your real seed phrase and transforms it into a different (but still valid) seed phrase using a password you choose.

---

## 🤔 How Does It Work? (Explain Like I'm 5)

Imagine you have a secret message written in LEGO blocks:

```
Your Real Seed = 🔴🔵🟡🟢🔴🔵🟡🟢🔴🔵🟡🟢
Your Password  = 🟠🟣⚫⚪🟠🟣⚫⚪🟠🟣⚫⚪
```

**Step 1: Mix them together**
```
Mixed Result = 🟤🟫🔶🔷🟤🟫🔶🔷🟤🟫🔶🔷
```

**Step 2: Turn it back into words**
```
Encrypted Seed = "title print auction tail road popular stove milk sort alarm napkin baby"
```

**To get your original back:** Use the same password with the encrypted seed, and it unmixes back to your original! 🎉

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Download and Run
```bash
# Download the script
wget https://github.com/moon-miner/bash-BIP39-seed-cypher/raw/main/SCypherV2.sh

# Make it executable
chmod +x SCypherV2.sh

# Run it
./SCypherV2.sh
```

### 2️⃣ Follow the Menu
```
SCypher v2.0 - XOR-based BIP39 Seed Cipher

Main Menu:
1. Encrypt/Decrypt seed phrase  ← Choose this
2. Help/License/Details
3. Exit

Select option [1-3]: 1
```

### 3️⃣ Enter Your Information
```
Enter seed phrase or input file to process:
> abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about

Enter password: ********
Confirm password: ********

Enter number of iterations (minimum 1): 55

Result:
crypto matrix future digital wallet secure random generate entropy blockchain system trust
```

**✨ Done!** Your seed is now encrypted.

---

## 🔄 To Decrypt (Get Original Back)

**Use the exact same process but with your encrypted seed:**

```
Enter seed phrase or input file to process:
> crypto matrix future digital wallet secure random generate entropy blockchain system trust

Enter password: ******** (SAME password)
Confirm password: ********

Enter number of iterations (minimum 1): 55 (SAME number)

Result:
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

**🎯 You get your original seed back!**

---

## 🔒 Security Made Simple

### Password Tips
- **Make it strong**: `MyDog$Loves2Swim!` ✅
- **Make it memorable**: You MUST remember it exactly
- **Keep it secret**: Don't share it with anyone

### Iteration Tips
- **More iterations = More security**
- **Start with 1,000** for testing
- **Use 10,000+** for real seeds
- **Remember the exact number** - you need it to decrypt

---

## ⚠️ Important Rules

### 📝 **ALWAYS Remember:**
1. **Your password** (exactly as you typed it)
2. **The iteration number** (exactly as you entered it)
3. **Keep a backup** of your original seed phrase

### 🚫 **NEVER:**
- Lose your password (no recovery possible)
- Change the iteration count (you won't get your original back)
- Use this for testing with real money at first

---

## 🛠️ Command Line (For Advanced Users)

**Encrypt and save to file:**
```bash
./SCypherV2.sh -f my_encrypted_seed.txt
```

**Silent mode (for scripts):**
```bash
echo "abandon ability able..." | ./SCypherV2.sh -s <<< $'MyPassword123\n1000'
```

---

## 🤝 Common Questions

**Q: Is the encrypted seed phrase real?**  
A: Yes! You can import it into any wallet. It will create a different wallet than your original.

**Q: What if I forget my password?**  
A: Your original seed is lost forever. There's no recovery.

**Q: Can I use the same password for multiple seeds?**  
A: You can, but it's not recommended. Use different passwords for different seeds.

**Q: How do I know if it worked?**  
A: Test with a fake seed first. If you can encrypt and decrypt it back to the original, it works!

---

## ✅ Quick Test (Try This First!)

**Use this test seed phrase:**
```
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

**Encrypt it with password:** `test123` and `100` iterations

**Expected result: odor surround judge crack muscle move stable define output edit gadget oil**
```
You should get a different valid seed phrase
```

**Then decrypt that result** with same password and iterations:
```
You should get back: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

**If this works, you understand how to use SCypher! 🎉**

---

## 📞 Need Help?

- **Read the error messages** - they usually tell you what's wrong
- **Check your password** - make sure it's exactly the same
- **Verify iteration count** - must be the same number
- **Test with fake seeds first** - don't risk real money

---

**🔐 Remember: SCypher is like a secret code machine. Same password + same iterations = get your original back. Different password = different result forever.**

**⚡ Quick Summary:**
1. **Download & run** the script
2. **Enter your seed phrase** and choose a strong password
3. **Remember your password and iteration count**
4. **Your encrypted seed looks like a normal seed phrase**
5. **Use same password + iterations to decrypt**

That's it! 🚀
