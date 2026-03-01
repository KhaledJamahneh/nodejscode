// src/utils/context.js
// Request context tracking using AsyncLocalStorage

const { AsyncLocalStorage } = require('async_hooks');

const asyncLocalStorage = new AsyncLocalStorage();

// Get current request context
const getContext = () => {
  return asyncLocalStorage.getStore() || {};
};

// Set request context
const setContext = (context) => {
  return asyncLocalStorage.run(context, () => context);
};

// Run callback with context
const runWithContext = (context, callback) => {
  return asyncLocalStorage.run(context, callback);
};

module.exports = {
  asyncLocalStorage,
  getContext,
  setContext,
  runWithContext
};
