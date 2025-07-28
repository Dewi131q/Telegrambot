# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release of VPN Auto Install Script
- Multi-protocol support (SSH, VLESS, VMess, Trojan)
- Interactive menu system with colorful output
- System monitoring and status display
- Web interface for account management
- Automatic service setup (Dropbear, Nginx)
- Account creation with detailed output
- Domain and banner management
- Port checking functionality
- Utility functions for system information
- WebSocket support for all protocols
- TLS encryption support
- Automatic UUID generation for VLESS/VMess
- Random password generation for Trojan
- Account file generation with detailed information
- Alias command for easy menu access

### Features
- **SSH Account Creation**: Create SSH accounts with expiration, IP limit, and quota
- **VLESS Account Creation**: Create VLESS accounts with WebSocket support
- **VMess Account Creation**: Create VMess accounts with WebSocket support
- **Trojan Account Creation**: Create Trojan accounts with WebSocket support
- **Domain Management**: Change server domain easily
- **Banner Management**: Customize server banner
- **Port Monitoring**: Check active ports and services
- **System Information**: Display IP, RAM, CPU, Domain info
- **Service Status**: Monitor Dropbear, Nginx, XRAY services
- **Web Dashboard**: Access account files via web browser

### Technical Details
- Compatible with Debian 10/11 and Ubuntu 20.04+
- Requires root access for installation
- Uses systemd for service management
- Implements secure password hashing
- Generates proper JSON configurations
- Creates detailed account documentation
- Implements proper file permissions
- Uses color-coded terminal output
- Implements error handling and validation

### Security
- Secure password handling
- Proper file permissions
- Service isolation
- Input validation
- Error handling

### Documentation
- Comprehensive README.md
- Installation instructions
- Usage guide
- Troubleshooting section
- Contributing guidelines
- License information