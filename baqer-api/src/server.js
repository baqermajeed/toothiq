const app = require('./app');
const env = require('./config/env');
const { connectDb } = require('./config/db');

connectDb()
  .then(() => {
    require('./models');
    // Initialize FCM service
    const fcmService = require('./services/fcmService');
    fcmService.init();
    // Shops stay open 24h (no auto open/close by openHours)
    const { disableScheduledShopHours } = require('./jobs/shopOpenCloseJob');
    disableScheduledShopHours();
    // Daily drivers report to Telegram at 11:56 Baghdad
    const { startDailyReportJob } = require('./jobs/dailyReportJob');
    startDailyReportJob();

    const server = app.listen(env.port, () => {
      console.log(`Server running on port ${env.port} (${env.nodeEnv})`);
    });
    const { setupSocketIO } = require('./socket');
    setupSocketIO(server);
    return server;
  })
  .catch((err) => {
    console.error('Failed to start server:', err);
    process.exit(1);
  });
