# Client Configuration Examples

This document provides examples of client configurations for different VPN protocols supported by the VPN Auto Installer.

## SSH/SSL Client Configurations

### HTTP Injector
```
PAYLOAD METHOD: GET / HTTP/1.1[crlf]Host: yourdomain.com[crlf]Upgrade: websocket[crlf][crlf]
PROXY HOST: yourdomain.com
PROXY PORT: 80 or 443
SSH HOST: yourdomain.com
SSH PORT: 22 or 143
USERNAME: [your_username]
PASSWORD: [your_password]
```

### HTTP Custom (Eproxy)
```
PAYLOAD:
GET / HTTP/1.1[crlf]
Host: yourdomain.com[crlf]
Upgrade: websocket[crlf]
Connection: Upgrade[crlf][crlf]

PROXY HOST: yourdomain.com
PROXY PORT: 80
SSH HOST: yourdomain.com
SSH PORT: 22
```

### KPN Tunnel Rev
```
Server Host: yourdomain.com
Server Port: 22
Username: [your_username]  
Password: [your_password]
Proxy Host: yourdomain.com
Proxy Port: 80

Advanced Settings:
Custom Payload: GET / HTTP/1.1[crlf]Host: yourdomain.com[crlf]Upgrade: websocket[crlf][crlf]
```

## VLESS Client Configurations

### V2rayNG (Android)
1. Open V2rayNG app
2. Click "+" button
3. Select "Manual Input [VLESS]"
4. Fill in the details:
   - **Remarks**: VLESS-[username]
   - **Address**: yourdomain.com
   - **Port**: 8080
   - **ID**: [generated_uuid]
   - **Flow**: (leave empty)
   - **Encryption**: none
   - **Network**: ws
   - **Path**: /vless
   - **Host**: yourdomain.com
   - **TLS**: none

### v2ray-core (Linux/Windows)
```json
{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "yourdomain.com",
            "port": 8080,
            "users": [
              {
                "id": "[generated_uuid]",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless",
          "headers": {
            "Host": "yourdomain.com"
          }
        }
      }
    }
  ]
}
```

### Clash Config (YAML)
```yaml
proxies:
  - name: "VLESS-Server"
    type: vless
    server: yourdomain.com
    port: 8080
    uuid: [generated_uuid]
    network: ws
    ws-opts:
      path: /vless
      headers:
        Host: yourdomain.com
```

## VMess Client Configurations

### V2rayNG (Android)
```
Address: yourdomain.com
Port: 8443
ID: [generated_uuid]
AlterID: 0
Security: auto
Network: ws
Path: /vmess
Host: yourdomain.com
TLS: none
```

### v2ray-core Configuration
```json
{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "yourdomain.com",
            "port": 8443,
            "users": [
              {
                "id": "[generated_uuid]",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess",
          "headers": {
            "Host": "yourdomain.com"
          }
        }
      }
    }
  ]
}
```

### Clash Config (YAML)
```yaml
proxies:
  - name: "VMess-Server"
    type: vmess
    server: yourdomain.com
    port: 8443
    uuid: [generated_uuid]
    alterId: 0
    cipher: auto
    network: ws
    ws-opts:
      path: /vmess
      headers:
        Host: yourdomain.com
```

## Trojan Client Configurations

### Clash Config (YAML)
```yaml
proxies:
  - name: "Trojan-Server"
    type: trojan
    server: yourdomain.com
    port: 2096
    password: [generated_password]
    network: ws
    ws-opts:
      path: /trojan
      headers:
        Host: yourdomain.com
```

### v2ray-core Configuration
```json
{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "trojan",
      "settings": {
        "servers": [
          {
            "address": "yourdomain.com",
            "port": 2096,
            "password": "[generated_password]"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan",
          "headers": {
            "Host": "yourdomain.com"
          }
        }
      }
    }
  ]
}
```

## Popular Client Applications

### Android
- **V2rayNG**: Best for VLESS/VMess/Trojan
- **HTTP Injector**: Best for SSH/SSL tunneling
- **KPN Tunnel Rev**: Alternative for SSH/SSL
- **Clash for Android**: Universal client

### iOS
- **Shadowrocket**: Premium app, supports all protocols
- **Quantumult X**: Advanced features, supports all protocols
- **OneClick**: Free alternative

### Windows
- **v2rayN**: GUI for v2ray-core
- **Clash for Windows**: User-friendly interface
- **Qv2ray**: Advanced configuration options

### Linux
- **v2ray-core**: Command line client
- **Clash**: Command line with web UI
- **Qv2ray**: GUI application

### macOS
- **V2rayU**: Native macOS client
- **ClashX**: Native Clash client
- **V2rayX**: Simple and lightweight

## Connection Testing

### Test SSH Connection
```bash
ssh -p 22 username@yourdomain.com
# or
ssh -p 143 username@yourdomain.com
```

### Test HTTP Proxy
```bash
curl -x http://yourdomain.com:80 http://httpbin.org/ip
```

### Test SOCKS Proxy (if configured)
```bash
curl --socks5-hostname localhost:1080 http://httpbin.org/ip
```

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if server port is open
   - Verify firewall settings
   - Confirm service is running

2. **Authentication Failed**
   - Verify username/password for SSH
   - Check UUID for VLESS/VMess
   - Confirm password for Trojan

3. **DNS Issues**
   - Use IP address instead of domain
   - Check domain DNS resolution
   - Try different DNS servers

4. **Slow Connection**
   - Test different ports
   - Check server resources
   - Try different protocols

### Port Testing
```bash
# Test port connectivity
telnet yourdomain.com 8080
# or
nc -zv yourdomain.com 8080
```

### DNS Testing
```bash
# Test domain resolution
nslookup yourdomain.com
# or
dig yourdomain.com
```