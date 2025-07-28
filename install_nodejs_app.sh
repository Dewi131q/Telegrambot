#!/bin/bash

# Node.js App Auto Install Script
# Jalankan script ini setelah vps_auto_install.sh selesai

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m[ERROR]\033[0m Script ini harus dijalankan sebagai root (sudo)"
   exit 1
fi

print_status "Memulai instalasi aplikasi Node.js..."

# Get project name
read -p "Masukkan nama project Node.js: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    print_warning "Nama project tidak diisi, menggunakan 'nodejs-app'"
    PROJECT_NAME="nodejs-app"
fi

# Get domain name
read -p "Masukkan domain name (contoh: example.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_warning "Domain tidak diisi, menggunakan localhost"
    DOMAIN_NAME="localhost"
fi

# Get port number
read -p "Masukkan port aplikasi (default: 3000): " APP_PORT

if [ -z "$APP_PORT" ]; then
    APP_PORT="3000"
fi

# Create application directory
mkdir -p /var/www/$DOMAIN_NAME
cd /var/www/$DOMAIN_NAME

# Create package.json
print_status "Membuat package.json..."
cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Node.js application",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF

# Create basic Express app
print_status "Membuat aplikasi Express.js..."
cat > app.js << EOF
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || $APP_PORT;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to $PROJECT_NAME API',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        timestamp: new Date().toISOString()
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
    console.log(\`Environment: \${process.env.NODE_ENV || 'development'}\`);
});
EOF

# Create .env file
cat > .env << EOF
NODE_ENV=production
PORT=$APP_PORT
EOF

# Create .gitignore
cat > .gitignore << EOF
node_modules/
.env
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.DS_Store
EOF

# Install dependencies
print_status "Menginstall dependencies..."
npm install

# Create PM2 ecosystem file
print_status "Membuat konfigurasi PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '$PROJECT_NAME',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: $APP_PORT
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: $APP_PORT
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Create logs directory
mkdir -p logs

# Set permissions
chown -R www-data:www-data /var/www/$DOMAIN_NAME
chmod -R 755 /var/www/$DOMAIN_NAME

# Create nginx configuration for Node.js app
print_status "Membuat konfigurasi Nginx untuk Node.js app..."
cat > /etc/nginx/sites-available/$DOMAIN_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:$APP_PORT/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# Start application with PM2
print_status "Menjalankan aplikasi dengan PM2..."
cd /var/www/$DOMAIN_NAME
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup

print_success "Aplikasi Node.js berhasil diinstall!"

echo ""
echo "=== INFORMASI NODE.JS APP ==="
echo "URL: http://$DOMAIN_NAME"
echo "Project Name: $PROJECT_NAME"
echo "Port: $APP_PORT"
echo "PM2 Process: $PROJECT_NAME"
echo ""
echo "Perintah Berguna:"
echo "- Masuk ke direktori: cd /var/www/$DOMAIN_NAME"
echo "- Restart app: pm2 restart $PROJECT_NAME"
echo "- Stop app: pm2 stop $PROJECT_NAME"
echo "- View logs: pm2 logs $PROJECT_NAME"
echo "- Monitor: pm2 monit"
echo ""
echo "Langkah selanjutnya:"
echo "1. Akses http://$DOMAIN_NAME"
echo "2. Edit app.js sesuai kebutuhan"
echo "3. Install SSL dengan: certbot --nginx -d $DOMAIN_NAME"
echo ""