# Secure SSH Key Management

This guide explains how to handle SSH keys securely while using dotfiles.

## Important Security Principles

1. **Never commit private keys to your repository**
   - Private keys should never be in your git repo, even if it's private
   - We've added patterns to `.gitignore` to prevent accidental commits

2. **Keep private keys secure**
   - Use `chmod 600` for all private keys
   - Use `chmod 700` for the `.ssh` directory
   - The `manage_ssh_keys.sh` script helps maintain proper permissions

3. **Add passphrases to unprotected keys**
   - Keys without passphrases are a security risk if your device is compromised
   - Use the script to add passphrases to existing keys

## Managing SSH Keys Across Machines

### Method 1: Manual Transfer (Recommended)

Manually transfer your keys to new machines using a secure method:
```bash
# On your current machine
./scripts/ssh/manage_ssh_keys.sh backup ~/secure_backup

# Transfer using a secure method (encrypted USB, secure cloud storage, etc.)

# On the new machine
./scripts/ssh/manage_ssh_keys.sh restore ~/secure_backup
```

### Method 2: Secure Backup Service

Use a secure password manager or encrypted cloud service that supports file attachments:
1. Back up your keys using the script
2. Upload the backup to your secure service
3. Download and restore on new machines

## Recommended Workflow

1. **Check your keys for passphrases**
   ```bash
   ./scripts/ssh/manage_ssh_keys.sh check-passphrases
   ```

2. **Add passphrases to unprotected keys**
   ```bash
   ./scripts/ssh/manage_ssh_keys.sh add-passphrase id_ed25519
   ```

3. **Fix permissions on all keys**
   ```bash
   ./scripts/ssh/manage_ssh_keys.sh fix-permissions
   ```

4. **Create a secure backup**
   ```bash
   ./scripts/ssh/manage_ssh_keys.sh backup ~/secure_location
   ```

## Managing Multiple Keys

For multiple SSH keys (work, personal, etc.), update your SSH config to specify which key to use for different hosts:

```
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

Then you can use these aliases in your git commands:
```bash
git clone git@github-personal:username/repo.git
``` 