# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added
- Initial release of VPN Auto Installer
- Multi-protocol support (SSH, VLESS, VMess, Trojan)
- Interactive menu system with color-coded interface
- Account management system with create, list, delete, renew functions
- Domain management with DNS validation
- Custom banner system with ASCII art support
- Port monitoring and connectivity testing
- System monitoring (RAM, CPU, disk usage)
- Firewall auto-configuration
- Automatic expired account cleanup
- Activity logging system
- WebSocket support for all protocols
- Nginx reverse proxy configuration
- Dropbear SSH server integration
- Xray-core installation and configuration

### Features
- **SSH Account Management**
  - Create accounts with password, expiry, and connection limits
  - Connection monitoring and active session tracking
  - Payload generation for WebSocket tunneling
  
- **VLESS Protocol Support**
  - UUID-based authentication
  - WebSocket transport with custom paths
  - Direct config link generation
  
- **VMess Protocol Support**
  - UUID and AlterID configuration
  - Base64 encoded config links
  - WebSocket transport support
  
- **Trojan Protocol Support**
  - Password-based authentication
  - WebSocket transport implementation
  - Direct config link generation
  
- **Domain Management**
  - Custom domain support with DNS validation
  - IP address fallback option
  - Automatic service configuration updates
  
- **System Monitoring**
  - Real-time port status checking
  - Network connectivity testing
  - Service status monitoring
  - Resource usage tracking
  
- **Security Features**
  - Automatic firewall configuration
  - User account isolation
  - Connection limit enforcement
  - Activity logging and audit trail

### Technical Details
- **Supported OS**: Debian 10/11, Ubuntu 20.04+
- **Dependencies**: Xray-core, Nginx, Dropbear SSH, jq, curl
- **Ports Used**: 22 (SSH), 143 (Dropbear), 80/443 (HTTP/HTTPS), 8080 (VLESS), 8443 (VMess), 2096 (Trojan), 10000 (WebSocket)
- **Storage**: `/etc/vpn-script/` for configurations, `/usr/local/bin/vpn-script/` for scripts

### Installation
- Single command installation from GitHub
- Local installation support for development
- Automatic dependency resolution
- Service auto-configuration

### Documentation
- Comprehensive README with setup instructions
- Client configuration examples
- Troubleshooting guide
- API documentation for all scripts

---

## [Unreleased]

### Planned Features
- SSL/TLS certificate integration
- Multi-user panel with web interface
- Usage statistics and reporting
- Backup and restore functionality
- API endpoints for automation
- Docker container support
- Load balancing configuration
- Advanced traffic shaping

### Known Issues
- Domain validation may fail with some DNS providers
- Port 22 conflicts with existing SSH on some systems
- IPv6 support not fully implemented

---

## Version History

### Version 1.0.0 (2024-01-15)
- Initial public release
- Core functionality implementation
- Basic documentation
- Test suite creation

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Support

For support and bug reports, please visit:
- [GitHub Issues](https://github.com/username/vpn-auto-installer/issues)
- [Documentation Wiki](https://github.com/username/vpn-auto-installer/wiki)