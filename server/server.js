const express = require('express');
const cors = require('cors');
const { sequelize, User, Task, Category } = require('./models');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = 5000;
const JWT_SECRET = 'secretkey';

app.use(cors());
app.use(express.json());

// ---------- Аутентификация ----------
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    const normalizedEmail = email.toLowerCase();
    const existing = await User.findOne({ where: { email: normalizedEmail } });
    if (existing) return res.status(400).json({ message: 'Email уже зарегистрирован' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({ username, email: normalizedEmail, password: hashed });
    res.status(201).json({ message: 'Пользователь создан' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.toLowerCase();
    const user = await User.findOne({ where: { email: normalizedEmail } });
    if (!user) return res.status(401).json({ message: 'Неверный email или пароль' });
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: 'Неверный email или пароль' });
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email } });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// ---------- Middleware для проверки токена ----------
const auth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Токен отсутствует' });
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findByPk(decoded.id);
    if (!user) return res.status(401).json({ message: 'Пользователь не найден' });
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Недействительный токен' });
  }
};

// ---------- Задачи (CRUD) ----------
app.get('/api/tasks', auth, async (req, res) => {
  try {
    const { status, priority, categoryId, sortBy, order } = req.query;
    const where = { userId: req.user.id };
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (categoryId) where.categoryId = categoryId;
    const orderClause = sortBy ? [[sortBy, order === 'desc' ? 'DESC' : 'ASC']] : [['createdAt', 'DESC']];
    const tasks = await Task.findAll({
      where,
      order: orderClause,
      include: [{ model: Category, attributes: ['id', 'name'] }]
    });
    res.json(tasks);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка получения задач' });
  }
});

app.post('/api/tasks', auth, async (req, res) => {
  try {
    const { title, description, status, priority, deadline, categoryId } = req.body;
    const task = await Task.create({
      title,
      description,
      status: status || 'новая',
      priority: priority || 'средний',
      deadline,
      userId: req.user.id,
      categoryId: categoryId || null
    });
    res.status(201).json(task);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка создания задачи' });
  }
});

app.put('/api/tasks/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!task) return res.status(404).json({ message: 'Задача не найдена' });
    const { title, description, status, priority, deadline, categoryId } = req.body;
    await task.update({
      title: title || task.title,
      description: description !== undefined ? description : task.description,
      status: status || task.status,
      priority: priority || task.priority,
      deadline: deadline !== undefined ? deadline : task.deadline,
      categoryId: categoryId !== undefined ? categoryId : task.categoryId
    });
    res.json(task);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка обновления задачи' });
  }
});

app.delete('/api/tasks/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!task) return res.status(404).json({ message: 'Задача не найдена' });
    await task.destroy();
    res.json({ message: 'Задача удалена' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка удаления задачи' });
  }
});

// ---------- Категории (CRUD) ----------
app.get('/api/categories', auth, async (req, res) => {
  try {
    const categories = await Category.findAll({
      where: { userId: req.user.id },
      order: [['name', 'ASC']]
    });
    res.json(categories);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка получения категорий' });
  }
});

app.post('/api/categories', auth, async (req, res) => {
  try {
    const { name } = req.body;
    const category = await Category.create({ name, userId: req.user.id });
    res.status(201).json(category);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка создания категории' });
  }
});

app.put('/api/categories/:id', auth, async (req, res) => {
  try {
    const category = await Category.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!category) return res.status(404).json({ message: 'Категория не найдена' });
    const { name } = req.body;
    await category.update({ name });
    res.json(category);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка обновления категории' });
  }
});

app.delete('/api/categories/:id', auth, async (req, res) => {
  try {
    const category = await Category.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!category) return res.status(404).json({ message: 'Категория не найдена' });
    await category.destroy();
    res.json({ message: 'Категория удалена' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка удаления категории' });
  }
});

// ---------- Запуск ----------
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await sequelize.sync();
  console.log('Database synchronized');
});