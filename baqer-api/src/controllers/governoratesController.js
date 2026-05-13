const { IRAQ_GOVERNORATES } = require('../config/iraqGovernorates');

function list(req, res) {
  res.json({ success: true, data: IRAQ_GOVERNORATES });
}

module.exports = { list };
