## Features
- Adds public key(s) in ~/.ssh/authorized_keys  
- Enables fallback to password + MFA (Google Authenticator)
- Guides the user in the MFA configuration on they phone/other device
- Supports any user of your choice

| Login Method    | Result                       | Client Authentication Method |
| --------------- | ---------------------------- | -----------------------------|
| SSH with key    | Logs in directly             | PublicKey                    |
| SSH without key | Prompts: Password → MFA code | Keyboard Interactive         |

Before closing the original session please ensure you can access the system by trying the new login in a new session.  

## Instructions
1) Clone the repository  
```git clone https://github.com/GianlucaUlivi/auto-setup-ssh-key-and-mfa-fallback-ubuntu```

2) Navigate to the new directory and make the script executable  
```cd auto-setup-ssh-key-and-mfa-fallback-ubuntu```  
```chmod + x auto-setup-ssh-key-mfa.sh```  

3) Run the script and follow the prompts during the execution  
```./auto-setup-ssh-key-mfa.sh```
