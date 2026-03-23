#!/bin/bash

echo "🚀 Setting up Weekend Cost Saver..."

# Check doctl
if ! command -v doctl &> /dev/null
then
    echo "❌ doctl not found. Install it first."
    exit
fi

# Copy env
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "📝 Created .env file. Please edit it before running scripts."
else
  echo "✅ .env already exists"
fi

chmod +x scripts/*.sh

echo "✅ Setup complete!"
echo "👉 Next steps:"
echo "1. Edit .env"
echo "2. Run ./scripts/shutdown.sh or ./scripts/startup.sh"
