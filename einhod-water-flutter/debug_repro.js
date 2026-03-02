const { query } = require('./src/config/database');
const clientController = require('./src/controllers/client.controller');

async function test() {
  const req = { user: { id: 1 } };
  const res = {
    status: (code) => {
      console.log('Status:', code);
      return res;
    },
    json: (data) => {
      console.log('JSON:', JSON.stringify(data, null, 2));
      return res;
    }
  };

  try {
    await clientController.getProfile(req, res);
  } catch (error) {
    console.error('Caught error:', error);
  }
}

test();
