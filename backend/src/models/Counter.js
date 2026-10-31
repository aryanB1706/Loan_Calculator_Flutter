const mongoose = require('mongoose');

// A tiny atomic sequence store used for readable application numbers such as
// LN-2026-000123. MongoDB's findOneAndUpdate with $inc avoids duplicate numbers
// when two applications are created at the same time.
const counterSchema = new mongoose.Schema({
  _id: {
    type: String,
    required: true,
  },
  seq: {
    type: Number,
    default: 0,
  },
});

module.exports = mongoose.model('Counter', counterSchema);
