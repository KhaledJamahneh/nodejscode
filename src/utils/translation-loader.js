// src/utils/translation-loader.js
// Hot-reload translations without server restart

const fs = require('fs');
const path = require('path');
const logger = require('./logger');

class TranslationLoader {
  constructor() {
    this.messagesCache = null;
    this.unitsCache = null;
    this.messagesPath = path.join(__dirname, '../locales/messages.json');
    this.unitsPath = path.join(__dirname, '../locales/units.json');
    
    // Watch for file changes in development
    if (process.env.NODE_ENV === 'development') {
      this.watchFiles();
    }
  }

  loadMessages() {
    if (!this.messagesCache) {
      this.messagesCache = this.readJSON(this.messagesPath);
    }
    return this.messagesCache;
  }

  loadUnits() {
    if (!this.unitsCache) {
      this.unitsCache = this.readJSON(this.unitsPath);
    }
    return this.unitsCache;
  }

  readJSON(filePath) {
    try {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    } catch (error) {
      logger.error(`Failed to load translations from ${filePath}:`, error);
      return {};
    }
  }

  watchFiles() {
    fs.watch(this.messagesPath, (eventType) => {
      if (eventType === 'change') {
        logger.info('Messages file changed, reloading...');
        this.messagesCache = null;
      }
    });

    fs.watch(this.unitsPath, (eventType) => {
      if (eventType === 'change') {
        logger.info('Units file changed, reloading...');
        this.unitsCache = null;
      }
    });
  }

  // Force reload (useful for production updates via API)
  reload() {
    this.messagesCache = null;
    this.unitsCache = null;
    logger.info('Translations reloaded');
  }
}

// Singleton instance
const loader = new TranslationLoader();

module.exports = loader;
