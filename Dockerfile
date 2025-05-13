FROM node:18

WORKDIR /app

# Copy backend package files
COPY backend/package*.json ./backend/

# Copy frontend package files
COPY frontend/package*.json ./frontend/

# Install backend dependencies
WORKDIR /app/backend
RUN npm install

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm install

# Copy the rest of the application
WORKDIR /app
COPY . .

# Build the frontend
WORKDIR /app/frontend
RUN npm run build

# Return to backend directory for server startup
WORKDIR /app/backend

# Set environment variables
ENV NODE_ENV=production \
    PORT=5000

# Expose the application port
EXPOSE 5000

# Start the application
CMD ["node", "backend/server.js"]
