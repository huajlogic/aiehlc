# Development Environment Setup Guide

This guide covers VS Code/Cursor debugging setup and SSH passwordless authentication.

---

## Part 1: VS Code / Cursor Debugging Setup

### Prerequisites: Install Python Extension

If you do not see **"Python File"** in the debugger list, it means the Python extension is not installed or enabled. Cursor (like VS Code) needs this extension to understand how to run and debug Python scripts.

#### Install the Python Extension

1. Click the **Extensions** icon in the left sidebar (it looks like four squares, or press `Ctrl+Shift+X`)
2. In the search bar, type `Python`
3. Look for the one named **"Python"** created by **Microsoft**
4. Click **Install**

#### Select Your Python Interpreter

Once the extension is installed, you must tell Cursor which Python to use:

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) to open the **Command Palette**
2. Type and select **"Python: Select Interpreter"**
3. Choose the **"Recommended"** version or the one installed on your system (e.g., Python 3.x)

After completing these steps, "Python File" should now appear in the debug configuration list.

---

### Step 1: Open Debug Panel

Press `Ctrl+Shift+D` (or `Cmd+Shift+D` on Mac) to open the **Run and Debug** panel.

### Step 2: Create launch.json

1. Click **"create a launch.json file"** link in the debug panel
2. Select **"Python"** from the environment dropdown
3. Select **"Python File"** as the debug configuration

This creates `.vscode/launch.json` in your workspace.

### Step 3: Configure launch.json

The default configuration runs the currently open file:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": true
        }
    ]
}
```

### Step 4: Add Custom Debug Configurations

Add more configurations for specific scripts:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": true
        },
        {
            "name": "Python: Main Test",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/test/aiehlcmaintest.py",
            "console": "integratedTerminal",
            "justMyCode": true,
            "cwd": "${workspaceFolder}"
        },
        {
            "name": "Python: With Arguments",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/your_script.py",
            "args": ["--input", "data.txt", "--verbose"],
            "console": "integratedTerminal",
            "justMyCode": true
        }
    ]
}
```

### Step 5: Run Debug

1. Open a Python file (`.py`)
2. Press `F5` to start debugging
3. Or select a configuration from the dropdown and click the green play button

### Debug Features

| Key | Action |
|-----|--------|
| `F5` | Start/Continue debugging |
| `F9` | Toggle breakpoint |
| `F10` | Step over |
| `F11` | Step into |
| `Shift+F11` | Step out |
| `Shift+F5` | Stop debugging |

### Common launch.json Options

| Option | Description |
|--------|-------------|
| `program` | Path to Python script to run |
| `args` | Command line arguments |
| `cwd` | Working directory |
| `env` | Environment variables |
| `justMyCode` | Skip debugging library code |
| `console` | Where to show output |

### Important Notes

- **Do NOT press F5 with non-Python files open** (like `.json` or `.sh`) - it will try to run them as Python
- Always open a `.py` file before pressing F5, or select a specific configuration

### Troubleshooting: Manually Create launch.json

If the debug configuration menu still doesn't show "Python File" after installing the extension, you can manually create the configuration:

1. In your project file explorer (left sidebar), look for a folder named `.vscode`
   - If it doesn't exist, create it
2. Inside `.vscode`, create a new file named `launch.json`
3. Paste the following code into that file:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "externalTerminal",
            "justMyCode": true
        }
    ]
}
```

4. Save the file
5. Open your Python script (e.g., `aiehlcmaintest.py`) and press `F5`
6. It should now launch in an external terminal window

**Note:** You can change `"console": "externalTerminal"` to `"console": "integratedTerminal"` if you prefer the output to appear in Cursor's built-in terminal instead.

---

## Part 2: SSH Public Key Authentication Setup

This section explains how to enable passwordless SSH login to remote servers like `<username>@10.***.***.***`.

### Prerequisites

- Access to both local machine and remote server
- SSH client installed on local machine
- SSH server running on remote server

### Step 1: Generate SSH Key Pair (Local Machine)

If you don't already have an SSH key, generate one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

- Press Enter to accept default location (`~/.ssh/id_ed25519`)
- Optionally set a passphrase (or press Enter for no passphrase)

Verify the key was created:

```bash
ls -la ~/.ssh/id_ed25519*
```

### Step 2: Copy Public Key to Remote Server

### Option A: Using ssh-copy-id (Recommended)

```bash
ssh-copy-id <username>@10.***.***.***
```

Enter your password when prompted. The key will be automatically added.

### Option B: Manual Copy

1. Display your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. SSH to remote server (with password):
   ```bash
   ssh <username>@10.***.***.***
   ```

3. Add the key to authorized_keys:
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

### Step 3: Fix Permissions (CRITICAL)

SSH requires strict permissions. **This is the most common cause of key auth failure.**

### On Remote Server

```bash
# Home directory must NOT be group/world writable
chmod 755 ~

# .ssh directory must be 700
chmod 700 ~/.ssh

# authorized_keys must be 600
chmod 600 ~/.ssh/authorized_keys
```

### On Local Machine

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Step 4: Test Connection

```bash
ssh <username>@10.***.***.***
```

You should now login without being prompted for a password.

### Troubleshooting

### Still Asking for Password?

1. **Check permissions** (most common issue):
   ```bash
   # On remote server
   ls -ld ~ ~/.ssh ~/.ssh/authorized_keys
   ```
   
   Expected output:
   ```
   drwxr-xr-x ... /home/<username>           (755 - NOT 775 or 777!)
   drwx------ ... /home/<username>/.ssh      (700)
   -rw------- ... authorized_keys      (600)
   ```

2. **Debug the connection**:
   ```bash
   ssh -vvv <username>@10.***.***.*** 2>&1 | grep -i "auth\|key\|offer"
   ```

3. **Check server auth log** (on remote server):
   ```bash
   sudo tail -20 /var/log/auth.log
   ```

### Common Permission Errors

| Problem | Symptom | Fix |
|---------|---------|-----|
| Home dir group writable | `drwxrwx---` (770/775/777) | `chmod 755 ~` |
| .ssh wrong permissions | Not `drwx------` | `chmod 700 ~/.ssh` |
| authorized_keys wrong | Not `-rw-------` | `chmod 600 ~/.ssh/authorized_keys` |
| Wrong owner | Files owned by root | `chown -R <username>:<username> ~/.ssh` |

### Verify SSH Server Config

On remote server, check `/etc/ssh/sshd_config`:

```bash
grep -E "^(PubkeyAuthentication|StrictModes|AuthorizedKeysFile)" /etc/ssh/sshd_config
```

Required settings (these are usually defaults):
```
PubkeyAuthentication yes
StrictModes yes
AuthorizedKeysFile .ssh/authorized_keys
```

### Optional: SSH Config for Easy Access

Create/edit `~/.ssh/config` on your local machine:

```
Host myserver
    HostName 10.***.***.***
    User <username>
    IdentityFile ~/.ssh/id_ed25519
```

Then connect with just:

```bash
ssh myserver
```

### Quick Reference

```bash
# Generate key
ssh-keygen -t ed25519 -C "email@example.com"

# Copy key to server
ssh-copy-id <username>@10.***.***.***

# Fix permissions on remote server
ssh <username>@10.***.***.*** "chmod 755 ~ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# Test connection
ssh <username>@10.***.***.***
```
