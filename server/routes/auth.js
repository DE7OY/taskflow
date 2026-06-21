const express = require('express');
const router = express.Router();

router.post('/login', (req, res) => {
  res.json({ message: 'Login route works!' });
});

router.post('/register', (req, res) => {
  res.json({ message: 'Register route works!' });
});

module.exports = router;