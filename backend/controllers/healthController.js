import mongoose from 'mongoose';

// @desc    Get application health status
// @route   GET /api/health
// @access  Public
const getHealth = async (req, res) => {
  try {
    // Check MongoDB connection
    const dbState = mongoose.connection.readyState;
    const dbStatus = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting',
    };

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: {
        status: dbStatus[dbState],
        connected: dbState === 1,
      },
      memory: {
        usage: process.memoryUsage(),
        free: process.env.NODE_ENV === 'development' ? require('os').freemem() : undefined,
      }
    };

    if (dbState !== 1) {
      health.status = 'degraded';
    }

    res.status(200).json(health);
  } catch (error) {
    res.status(500).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
};

export { getHealth };