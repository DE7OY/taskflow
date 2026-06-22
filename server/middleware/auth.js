const jwt = require('jsonwebtoken');
const { User } = require('../models');
const JWT_SECRET = 'secretkey';
module.exports = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Токен отсутствует' });
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findByPk(decoded.id);
    if (!user) return res.status(401).json({ message: 'Пользователь не найден' });
    req.user = user;
    next();
  } catch (e) { return res.status(401).json({ message: 'Недействительный токен' }); }
};
