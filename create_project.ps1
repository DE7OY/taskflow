# Создаём структуру папок
New-Item -ItemType Directory -Path "server\models", "server\routes", "server\middleware" -Force
New-Item -ItemType Directory -Path "client\public", "client\src\api", "client\src\context", "client\src\components" -Force

# ---------- SERVER ----------
@"
{
  "name": "taskflow-server",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.0",
    "sequelize": "^6.31.0",
    "sqlite3": "^5.1.6"
  }
}
"@ | Out-File -FilePath "server\package.json" -Encoding UTF8

@"
const express = require('express');
const cors = require('cors');
const { sequelize } = require('./models');
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const categoryRoutes = require('./routes/categories');

const app = express();
const PORT = 5000;
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/categories', categoryRoutes);

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await sequelize.sync({ alter: true });
  console.log('Database synchronized');
});
"@ | Out-File -FilePath "server\server.js" -Encoding UTF8

@"
const { Sequelize } = require('sequelize');
const sequelize = new Sequelize({ dialect: 'sqlite', storage: './database.sqlite', logging: false });
const User = require('./User')(sequelize);
const Task = require('./Task')(sequelize);
const Category = require('./Category')(sequelize);

User.hasMany(Task, { foreignKey: 'userId', onDelete: 'CASCADE' });
Task.belongsTo(User, { foreignKey: 'userId' });
User.hasMany(Category, { foreignKey: 'userId', onDelete: 'CASCADE' });
Category.belongsTo(User, { foreignKey: 'userId' });
Category.hasMany(Task, { foreignKey: 'categoryId', onDelete: 'SET NULL' });
Task.belongsTo(Category, { foreignKey: 'categoryId' });

module.exports = { sequelize, User, Task, Category };
"@ | Out-File -FilePath "server\models\index.js" -Encoding UTF8

@"
module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    username: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: false, unique: true, validate: { isEmail: true } },
    password: { type: DataTypes.STRING, allowNull: false }
  });
  return User;
};
"@ | Out-File -FilePath "server\models\User.js" -Encoding UTF8

@"
module.exports = (sequelize, DataTypes) => {
  const Task = sequelize.define('Task', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    title: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT },
    status: { type: DataTypes.ENUM('новая','в процессе','выполнена'), defaultValue: 'новая' },
    priority: { type: DataTypes.ENUM('низкий','средний','высокий'), defaultValue: 'средний' },
    deadline: { type: DataTypes.DATEONLY },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    categoryId: { type: DataTypes.INTEGER, allowNull: true }
  });
  return Task;
};
"@ | Out-File -FilePath "server\models\Task.js" -Encoding UTF8

@"
module.exports = (sequelize, DataTypes) => {
  const Category = sequelize.define('Category', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    userId: { type: DataTypes.INTEGER, allowNull: false }
  });
  return Category;
};
"@ | Out-File -FilePath "server\models\Category.js" -Encoding UTF8

@"
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
"@ | Out-File -FilePath "server\middleware\auth.js" -Encoding UTF8

@"
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const router = express.Router();
const JWT_SECRET = 'secretkey';

router.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    const existing = await User.findOne({ where: { email } });
    if (existing) return res.status(400).json({ message: 'Email уже зарегистрирован' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({ username, email, password: hashed });
    res.status(201).json({ message: 'Пользователь создан' });
  } catch (e) { res.status(500).json({ message: 'Ошибка сервера' }); }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(401).json({ message: 'Неверный email или пароль' });
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: 'Неверный email или пароль' });
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email } });
  } catch (e) { res.status(500).json({ message: 'Ошибка сервера' }); }
});
module.exports = router;
"@ | Out-File -FilePath "server\routes\auth.js" -Encoding UTF8

@"
const express = require('express');
const { Task, Category } = require('../models');
const auth = require('../middleware/auth');
const router = express.Router();

router.get('/', auth, async (req, res) => {
  try {
    const { status, priority, categoryId, sortBy, order } = req.query;
    const where = { userId: req.user.id };
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (categoryId) where.categoryId = categoryId;
    let orderClause = sortBy ? [[sortBy, order === 'desc' ? 'DESC' : 'ASC']] : [['createdAt','DESC']];
    const tasks = await Task.findAll({ where, order: orderClause, include: [{ model: Category, attributes: ['id','name'] }] });
    res.json(tasks);
  } catch (e) { res.status(500).json({ message: 'Ошибка получения задач' }); }
});

router.get('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ where: { id: req.params.id, userId: req.user.id }, include: [{ model: Category, attributes: ['id','name'] }] });
    if (!task) return res.status(404).json({ message: 'Задача не найдена' });
    res.json(task);
  } catch (e) { res.status(500).json({ message: 'Ошибка получения задачи' }); }
});

router.post('/', auth, async (req, res) => {
  try {
    const { title, description, status, priority, deadline, categoryId } = req.body;
    const task = await Task.create({ title, description, status: status || 'новая', priority: priority || 'средний', deadline, userId: req.user.id, categoryId: categoryId || null });
    res.status(201).json(task);
  } catch (e) { res.status(500).json({ message: 'Ошибка создания задачи' }); }
});

router.put('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!task) return res.status(404).json({ message: 'Задача не найдена' });
    const { title, description, status, priority, deadline, categoryId } = req.body;
    await task.update({ title: title || task.title, description: description !== undefined ? description : task.description, status: status || task.status, priority: priority || task.priority, deadline: deadline !== undefined ? deadline : task.deadline, categoryId: categoryId !== undefined ? categoryId : task.categoryId });
    res.json(task);
  } catch (e) { res.status(500).json({ message: 'Ошибка обновления задачи' }); }
});

router.delete('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!task) return res.status(404).json({ message: 'Задача не найдена' });
    await task.destroy();
    res.json({ message: 'Задача удалена' });
  } catch (e) { res.status(500).json({ message: 'Ошибка удаления задачи' }); }
});
module.exports = router;
"@ | Out-File -FilePath "server\routes\tasks.js" -Encoding UTF8

@"
const express = require('express');
const { Category } = require('../models');
const auth = require('../middleware/auth');
const router = express.Router();

router.get('/', auth, async (req, res) => {
  try {
    const categories = await Category.findAll({ where: { userId: req.user.id }, order: [['name','ASC']] });
    res.json(categories);
  } catch (e) { res.status(500).json({ message: 'Ошибка получения категорий' }); }
});
router.post('/', auth, async (req, res) => {
  try {
    const { name } = req.body;
    const category = await Category.create({ name, userId: req.user.id });
    res.status(201).json(category);
  } catch (e) { res.status(500).json({ message: 'Ошибка создания категории' }); }
});
router.put('/:id', auth, async (req, res) => {
  try {
    const category = await Category.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!category) return res.status(404).json({ message: 'Категория не найдена' });
    const { name } = req.body;
    await category.update({ name });
    res.json(category);
  } catch (e) { res.status(500).json({ message: 'Ошибка обновления категории' }); }
});
router.delete('/:id', auth, async (req, res) => {
  try {
    const category = await Category.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!category) return res.status(404).json({ message: 'Категория не найдена' });
    await category.destroy();
    res.json({ message: 'Категория удалена' });
  } catch (e) { res.status(500).json({ message: 'Ошибка удаления категории' }); }
});
module.exports = router;
"@ | Out-File -FilePath "server\routes\categories.js" -Encoding UTF8

# ---------- CLIENT ----------
@"
{
  "name": "taskflow-client",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "axios": "^1.6.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "proxy": "http://localhost:5000"
}
"@ | Out-File -FilePath "client\package.json" -Encoding UTF8

@"
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>TaskFlow</title></head><body><div id="root"></div></body></html>
"@ | Out-File -FilePath "client\public\index.html" -Encoding UTF8

@"
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<React.StrictMode><App /></React.StrictMode>);
"@ | Out-File -FilePath "client\src\index.js" -Encoding UTF8

@"
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif; background: #f4f7fc; color: #333; }
a { color: #4a6fa5; text-decoration: none; }
button { cursor: pointer; font-family: inherit; }
input, select, textarea { font-family: inherit; }
"@ | Out-File -FilePath "client\src\index.css" -Encoding UTF8

@"
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './components/Login';
import Register from './components/Register';
import TaskList from './components/TaskList';

const PrivateRoute = ({ children }) => {
  const { user } = useAuth();
  return user ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/" element={<PrivateRoute><TaskList /></PrivateRoute>} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
export default App;
"@ | Out-File -FilePath "client\src\App.js" -Encoding UTF8

@"
import axios from 'axios';
const api = axios.create({ baseURL: 'http://localhost:5000/api' });
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  },
  error => Promise.reject(error)
);
export default api;
"@ | Out-File -FilePath "client\src\api\axios.js" -Encoding UTF8

@"
import React, { createContext, useState, useContext, useEffect } from 'react';
import api from '../api/axios';
const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const token = localStorage.getItem('token');
    const storedUser = localStorage.getItem('user');
    if (token && storedUser) {
      setUser(JSON.parse(storedUser));
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    }
    setLoading(false);
  }, []);
  const login = async (email, password) => {
    const res = await api.post('/auth/login', { email, password });
    const { token, user } = res.data;
    localStorage.setItem('token', token);
    localStorage.setItem('user', JSON.stringify(user));
    api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    setUser(user);
    return user;
  };
  const register = async (username, email, password) => {
    const res = await api.post('/auth/register', { username, email, password });
    return res.data;
  };
  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    delete api.defaults.headers.common['Authorization'];
    setUser(null);
  };
  return (
    <AuthContext.Provider value={{ user, login, register, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};
export const useAuth = () => useContext(AuthContext);
"@ | Out-File -FilePath "client\src\context\AuthContext.js" -Encoding UTF8

@"
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { login } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await login(email, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.message || 'Ошибка входа');
    }
  };

  const styles = {
    container: { display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', background: '#f4f7fc' },
    card: { background: '#fff', padding: '40px 50px', borderRadius: '12px', boxShadow: '0 4px 20px rgba(0,0,0,0.08)', width: '100%', maxWidth: '420px' },
    logo: { fontSize: '32px', fontWeight: 'bold', color: '#4a6fa5', marginBottom: '8px', textAlign: 'center' },
    subtitle: { fontSize: '18px', fontWeight: '400', color: '#555', marginBottom: '24px', textAlign: 'center' },
    field: { marginBottom: '18px' },
    input: { width: '100%', padding: '10px 14px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '16px', marginTop: '6px' },
    button: { width: '100%', padding: '12px', backgroundColor: '#4a6fa5', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '18px', fontWeight: '600' },
    error: { color: '#d32f2f', background: '#ffebee', padding: '10px', borderRadius: '6px', marginBottom: '16px', textAlign: 'center' },
    link: { textAlign: 'center', marginTop: '18px', fontSize: '15px' }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.logo}>TaskFlow</h1>
        <h2 style={styles.subtitle}>Войдите в свой аккаунт</h2>
        {error && <div style={styles.error}>{error}</div>}
        <form onSubmit={handleSubmit}>
          <div style={styles.field}><label>Email</label><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="user@example.com" required style={styles.input} /></div>
          <div style={styles.field}><label>Пароль</label><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="********" required style={styles.input} /></div>
          <button type="submit" style={styles.button}>Войти</button>
        </form>
        <p style={styles.link}>Нет аккаунта? <Link to="/register">Зарегистрироваться</Link></p>
      </div>
    </div>
  );
}
export default Login;
"@ | Out-File -FilePath "client\src\components\Login.js" -Encoding UTF8

@"
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

function Register() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();
  const { register } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await register(username, email, password);
      setSuccess('Регистрация успешна! Теперь войдите.');
      setTimeout(() => navigate('/login'), 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Ошибка регистрации');
    }
  };

  const styles = {
    container: { display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', background: '#f4f7fc' },
    card: { background: '#fff', padding: '40px 50px', borderRadius: '12px', boxShadow: '0 4px 20px rgba(0,0,0,0.08)', width: '100%', maxWidth: '420px' },
    logo: { fontSize: '32px', fontWeight: 'bold', color: '#4a6fa5', marginBottom: '8px', textAlign: 'center' },
    subtitle: { fontSize: '18px', fontWeight: '400', color: '#555', marginBottom: '24px', textAlign: 'center' },
    field: { marginBottom: '18px' },
    input: { width: '100%', padding: '10px 14px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '16px', marginTop: '6px' },
    button: { width: '100%', padding: '12px', backgroundColor: '#4a6fa5', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '18px', fontWeight: '600' },
    error: { color: '#d32f2f', background: '#ffebee', padding: '10px', borderRadius: '6px', marginBottom: '16px', textAlign: 'center' },
    success: { color: '#2e7d32', background: '#e8f5e9', padding: '10px', borderRadius: '6px', marginBottom: '16px', textAlign: 'center' },
    link: { textAlign: 'center', marginTop: '18px', fontSize: '15px' }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.logo}>TaskFlow</h1>
        <h2 style={styles.subtitle}>Создайте аккаунт</h2>
        {error && <div style={styles.error}>{error}</div>}
        {success && <div style={styles.success}>{success}</div>}
        <form onSubmit={handleSubmit}>
          <div style={styles.field}><label>Имя пользователя</label><input type="text" value={username} onChange={(e) => setUsername(e.target.value)} placeholder="Иван" required style={styles.input} /></div>
          <div style={styles.field}><label>Email</label><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="user@example.com" required style={styles.input} /></div>
          <div style={styles.field}><label>Пароль</label><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="********" required style={styles.input} /></div>
          <button type="submit" style={styles.button}>Зарегистрироваться</button>
        </form>
        <p style={styles.link}>Уже есть аккаунт? <Link to="/login">Войти</Link></p>
      </div>
    </div>
  );
}
export default Register;
"@ | Out-File -FilePath "client\src\components\Register.js" -Encoding UTF8

# ----- TaskList.js (полный) -----
@"
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../api/axios';
import TaskForm from './TaskForm';
import CategorySidebar from './CategorySidebar';

function TaskList() {
  const { user, logout } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingTask, setEditingTask] = useState(null);
  const [filters, setFilters] = useState({ status: '', priority: '', categoryId: '' });
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState('desc');

  const fetchData = async () => {
    setLoading(true);
    try {
      const params = { ...filters, sortBy, order: sortOrder };
      Object.keys(params).forEach(k => { if (params[k] === '' || params[k] === null || params[k] === undefined) delete params[k]; });
      const [tasksRes, categoriesRes] = await Promise.all([
        api.get('/tasks', { params }),
        api.get('/categories')
      ]);
      setTasks(tasksRes.data);
      setCategories(categoriesRes.data);
    } catch (e) { console.error(e); } finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); }, [filters, sortBy, sortOrder]);

  const handleStatusChange = async (taskId, newStatus) => {
    try {
      const task = tasks.find(t => t.id === taskId);
      await api.put(`/tasks/${taskId}`, { ...task, status: newStatus });
      await fetchData();
    } catch (e) { console.error(e); }
  };

  const handleDelete = async (taskId) => {
    if (window.confirm('Удалить задачу?')) {
      try {
        await api.delete(`/tasks/${taskId}`);
        await fetchData();
      } catch (e) { console.error(e); }
    }
  };

  const handleEdit = (task) => { setEditingTask(task); setShowForm(true); };
  const handleFormClose = (refresh) => { setShowForm(false); setEditingTask(null); if (refresh) fetchData(); };
  const handleLogout = () => logout();

  const statuses = ['новая', 'в процессе', 'выполнена'];
  const priorities = ['низкий', 'средний', 'высокий'];

  const formatDate = (d) => new Date(d).toLocaleDateString('ru-RU');
  const getPriorityStyle = (p) => {
    switch (p) {
      case 'высокий': return { background: '#ffcdd2', color: '#c62828' };
      case 'средний': return { background: '#fff9c4', color: '#f57f17' };
      case 'низкий': return { background: '#c8e6c9', color: '#2e7d32' };
      default: return {};
    }
  };
  const getStatusStyle = (s) => {
    switch (s) {
      case 'выполнена': return { background: '#c8e6c9', color: '#2e7d32' };
      case 'в процессе': return { background: '#bbdefb', color: '#0d47a1' };
      default: return { background: '#e0e0e0', color: '#424242' };
    }
  };

  const styles = {
    container: { display: 'flex', minHeight: '100vh', background: '#f4f7fc' },
    main: { flex: 1, padding: '24px 32px', marginLeft: '240px' },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' },
    title: { fontSize: '28px', fontWeight: '600', color: '#1a1a1a' },
    headerRight: { display: 'flex', alignItems: 'center', gap: '16px' },
    userInfo: { fontSize: '16px', color: '#555' },
    logoutBtn: { padding: '6px 14px', border: '1px solid #ddd', borderRadius: '6px', background: 'transparent', fontSize: '14px' },
    newTaskBtn: { padding: '8px 18px', backgroundColor: '#4a6fa5', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '16px', fontWeight: '500' },
    filters: { display: 'flex', flexWrap: 'wrap', gap: '16px', marginBottom: '24px', padding: '16px', background: '#fff', borderRadius: '10px', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
    filterGroup: { display: 'flex', alignItems: 'center', gap: '8px' },
    select: { padding: '6px 12px', borderRadius: '6px', border: '1px solid #ddd', background: '#fff', fontSize: '14px' },
    taskGrid: { display: 'flex', flexDirection: 'column', gap: '16px' },
    taskCard: { background: '#fff', padding: '18px 20px', borderRadius: '10px', boxShadow: '0 1px 4px rgba(0,0,0,0.06)', borderLeft: '4px solid #4a6fa5' },
    cardHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' },
    taskTitle: { fontSize: '18px', fontWeight: '500', margin: 0 },
    cardActions: { display: 'flex', gap: '8px' },
    iconBtn: { background: 'transparent', border: 'none', fontSize: '18px', padding: '4px' },
    taskDesc: { marginTop: '6px', color: '#555', fontSize: '14px' },
    taskMeta: { display: 'flex', flexWrap: 'wrap', gap: '10px', marginTop: '12px', alignItems: 'center' },
    badge: { padding: '4px 12px', borderRadius: '20px', fontSize: '13px', fontWeight: '500' },
    deadline: { fontSize: '14px', color: '#777' },
    category: { fontSize: '14px', background: '#e8eaf6', padding: '2px 12px', borderRadius: '20px', color: '#3f51b5' },
    statusToggle: { display: 'flex', gap: '6px', marginTop: '12px' },
    activeStatus: { padding: '4px 12px', borderRadius: '20px', border: '1px solid #4a6fa5', background: '#4a6fa5', color: '#fff', fontSize: '13px' },
    inactiveStatus: { padding: '4px 12px', borderRadius: '20px', border: '1px solid #ddd', background: 'transparent', color: '#555', fontSize: '13px' },
    loading: { textAlign: 'center', padding: '40px', color: '#777' },
    empty: { textAlign: 'center', padding: '40px', color: '#999', fontSize: '18px' }
  };

  return (
    <div style={styles.container}>
      <CategorySidebar categories={categories} selectedCategoryId={filters.categoryId} onSelectCategory={(id) => setFilters({ ...filters, categoryId: id || '' })} onCategoryAdded={fetchData} />
      <div style={styles.main}>
        <div style={styles.header}>
          <h1 style={styles.title}>Все задачи</h1>
          <div style={styles.headerRight}>
            <span style={styles.userInfo}>{user?.username}</span>
            <button onClick={handleLogout} style={styles.logoutBtn}>Выйти</button>
            <button onClick={() => { setEditingTask(null); setShowForm(true); }} style={styles.newTaskBtn}>+ Новая задача</button>
          </div>
        </div>
        <div style={styles.filters}>
          <div style={styles.filterGroup}><label>Статус:</label><select value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })} style={styles.select}><option value="">Все</option>{statuses.map(s => <option key={s} value={s}>{s === 'новая' ? 'Новые' : s === 'в процессе' ? 'В процессе' : 'Выполнено'}</option>)}</select></div>
          <div style={styles.filterGroup}><label>Приоритет:</label><select value={filters.priority} onChange={(e) => setFilters({ ...filters, priority: e.target.value })} style={styles.select}><option value="">Все</option>{priorities.map(p => <option key={p} value={p}>{p.charAt(0).toUpperCase() + p.slice(1)}</option>)}</select></div>
          <div style={styles.filterGroup}><label>Сортировка:</label><select value={sortBy} onChange={(e) => setSortBy(e.target.value)} style={styles.select}><option value="createdAt">По дате создания</option><option value="deadline">По дедлайну</option><option value="priority">По приоритету</option></select><select value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} style={{ ...styles.select, width: '80px' }}><option value="desc">↓</option><option value="asc">↑</option></select></div>
        </div>
        {loading ? <div style={styles.loading}>Загрузка...</div> : (
          <div style={styles.taskGrid}>
            {tasks.length === 0 ? <div style={styles.empty}>Нет задач. Создайте первую!</div> : tasks.map(task => (
              <div key={task.id} style={styles.taskCard}>
                <div style={styles.cardHeader}><h3 style={styles.taskTitle}>{task.title}</h3><div style={styles.cardActions}><button onClick={() => handleEdit(task)} style={styles.iconBtn}>✏️</button><button onClick={() => handleDelete(task.id)} style={styles.iconBtn}>🗑️</button></div></div>
                {task.description && <div style={styles.taskDesc}>{task.description}</div>}
                <div style={styles.taskMeta}>
                  <span style={{ ...styles.badge, ...getPriorityStyle(task.priority) }}>{task.priority}</span>
                  <span style={{ ...styles.badge, ...getStatusStyle(task.status) }}>{task.status === 'новая' ? 'Новая' : task.status === 'в процессе' ? 'В процессе' : 'Выполнена'}</span>
                  {task.deadline && <span style={styles.deadline}>📅 {formatDate(task.deadline)}</span>}
                  {task.Category && <span style={styles.category}>{task.Category.name}</span>}
                </div>
                <div style={styles.statusToggle}>
                  <button onClick={() => handleStatusChange(task.id, 'новая')} style={task.status === 'новая' ? styles.activeStatus : styles.inactiveStatus}>Новая</button>
                  <button onClick={() => handleStatusChange(task.id, 'в процессе')} style={task.status === 'в процессе' ? styles.activeStatus : styles.inactiveStatus}>В процессе</button>
                  <button onClick={() => handleStatusChange(task.id, 'выполнена')} style={task.status === 'выполнена' ? styles.activeStatus : styles.inactiveStatus}>✅ Выполнена</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      {showForm && <TaskForm task={editingTask} categories={categories} onClose={handleFormClose} />}
    </div>
  );
}
export default TaskList;
"@ | Out-File -FilePath "client\src\components\TaskList.js" -Encoding UTF8

# ----- TaskForm.js -----
@"
import React, { useState, useEffect } from 'react';
import api from '../api/axios';

function TaskForm({ task, categories, onClose }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState('средний');
  const [categoryId, setCategoryId] = useState('');
  const [deadline, setDeadline] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (task) {
      setTitle(task.title || '');
      setDescription(task.description || '');
      setPriority(task.priority || 'средний');
      setCategoryId(task.categoryId || '');
      setDeadline(task.deadline || '');
    } else {
      setTitle('');
      setDescription('');
      setPriority('средний');
      setCategoryId('');
      setDeadline('');
    }
  }, [task]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim()) { setError('Название обязательно'); return; }
    setLoading(true); setError('');
    try {
      const data = { title, description, priority, categoryId: categoryId || null, deadline };
      if (task) await api.put(`/tasks/${task.id}`, data);
      else await api.post('/tasks', data);
      onClose(true);
    } catch (err) { setError('Ошибка сохранения'); } finally { setLoading(false); }
  };

  const styles = {
    overlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modal: { background: '#fff', padding: '32px', borderRadius: '12px', width: '100%', maxWidth: '520px', boxShadow: '0 8px 30px rgba(0,0,0,0.2)' },
    title: { fontSize: '24px', fontWeight: '600', marginBottom: '20px' },
    field: { marginBottom: '16px' },
    input: { width: '100%', padding: '10px 14px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '15px', marginTop: '4px' },
    select: { width: '100%', padding: '10px 14px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '15px', marginTop: '4px', background: '#fff' },
    row: { display: 'flex', gap: '16px' },
    actions: { display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' },
    cancelBtn: { padding: '10px 20px', border: '1px solid #ddd', borderRadius: '6px', background: 'transparent', fontSize: '16px', cursor: 'pointer' },
    submitBtn: { padding: '10px 24px', border: 'none', borderRadius: '6px', backgroundColor: '#4a6fa5', color: '#fff', fontSize: '16px', fontWeight: '500', cursor: 'pointer' },
    error: { color: '#d32f2f', background: '#ffebee', padding: '8px 12px', borderRadius: '6px', marginBottom: '16px' }
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.modal}>
        <h2 style={styles.title}>{task ? 'Редактировать задачу' : 'Новая задача'}</h2>
        {error && <div style={styles.error}>{error}</div>}
        <form onSubmit={handleSubmit}>
          <div style={styles.field}><label>Название</label><input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Введите название" required style={styles.input} /></div>
          <div style={styles.field}><label>Описание</label><textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Описание задачи..." rows="3" style={{ ...styles.input, resize: 'vertical' }} /></div>
          <div style={styles.row}>
            <div style={styles.field}><label>Приоритет</label><select value={priority} onChange={(e) => setPriority(e.target.value)} style={styles.select}><option value="низкий">Низкий</option><option value="средний">Средний</option><option value="высокий">Высокий</option></select></div>
            <div style={styles.field}><label>Категория</label><select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} style={styles.select}><option value="">Без категории</option>{categories.map(cat => <option key={cat.id} value={cat.id}>{cat.name}</option>)}</select></div>
          </div>
          <div style={styles.field}><label>Срок выполнения</label><input type="date" value={deadline} onChange={(e) => setDeadline(e.target.value)} style={styles.input} /></div>
          <div style={styles.actions}>
            <button type="button" onClick={() => onClose(false)} style={styles.cancelBtn}>Отмена</button>
            <button type="submit" disabled={loading} style={styles.submitBtn}>{loading ? 'Сохранение...' : (task ? 'Обновить' : 'Создать задачу')}</button>
          </div>
        </form>
      </div>
    </div>
  );
}
export default TaskForm;
"@ | Out-File -FilePath "client\src\components\TaskForm.js" -Encoding UTF8

# ----- CategorySidebar.js -----
@"
import React, { useState } from 'react';
import api from '../api/axios';

function CategorySidebar({ categories, selectedCategoryId, onSelectCategory, onCategoryAdded }) {
  const [newCategoryName, setNewCategoryName] = useState('');
  const [showInput, setShowInput] = useState(false);

  const handleAddCategory = async () => {
    if (!newCategoryName.trim()) return;
    try {
      await api.post('/categories', { name: newCategoryName });
      setNewCategoryName('');
      setShowInput(false);
      onCategoryAdded();
    } catch (e) { console.error(e); }
  };

  const styles = {
    sidebar: { position: 'fixed', top: 0, left: 0, bottom: 0, width: '240px', background: '#fff', padding: '24px 16px', boxShadow: '2px 0 8px rgba(0,0,0,0.04)', display: 'flex', flexDirection: 'column' },
    logo: { fontSize: '26px', fontWeight: 'bold', color: '#4a6fa5', marginBottom: '24px' },
    nav: { flex: 1, display: 'flex', flexDirection: 'column', gap: '4px' },
    navItem: { padding: '10px 14px', borderRadius: '8px', cursor: 'pointer', fontSize: '16px', transition: 'background 0.2s', color: '#333' },
    active: { background: '#e8edf4', fontWeight: '500', color: '#4a6fa5' },
    addCategory: { marginTop: '16px', borderTop: '1px solid #eee', paddingTop: '16px' },
    addBtn: { background: 'transparent', border: 'none', color: '#4a6fa5', fontSize: '15px', cursor: 'pointer', padding: '6px 0' },
    inputGroup: { display: 'flex', gap: '6px', alignItems: 'center' },
    input: { flex: 1, padding: '6px 10px', borderRadius: '6px', border: '1px solid #ddd', fontSize: '14px' },
    saveBtn: { padding: '6px 12px', background: '#4a6fa5', color: '#fff', border: 'none', borderRadius: '6px', fontSize: '14px', cursor: 'pointer' },
    cancelBtn: { background: 'transparent', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#999' }
  };

  return (
    <div style={styles.sidebar}>
      <h2 style={styles.logo}>TaskFlow</h2>
      <nav style={styles.nav}>
        <div style={{ ...styles.navItem, ...(selectedCategoryId === '' ? styles.active : {}) }} onClick={() => onSelectCategory('')}>Все задачи</div>
        {categories.map(cat => (
          <div key={cat.id} style={{ ...styles.navItem, ...(selectedCategoryId === cat.id ? styles.active : {}) }} onClick={() => onSelectCategory(cat.id)}>{cat.name}</div>
        ))}
      </nav>
      <div style={styles.addCategory}>
        {!showInput ? (
          <button onClick={() => setShowInput(true)} style={styles.addBtn}>+ Категория</button>
        ) : (
          <div style={styles.inputGroup}>
            <input type="text" value={newCategoryName} onChange={(e) => setNewCategoryName(e.target.value)} placeholder="Название" style={styles.input} />
            <button onClick={handleAddCategory} style={styles.saveBtn}>Сохранить</button>
            <button onClick={() => { setShowInput(false); setNewCategoryName(''); }} style={styles.cancelBtn}>×</button>
          </div>
        )}
      </div>
    </div>
  );
}
export default CategorySidebar;
"@ | Out-File -FilePath "client\src\components\CategorySidebar.js" -Encoding UTF8

Write-Host "✅ Все файлы созданы!" -ForegroundColor Green
Write-Host "Теперь выполните: cd server; npm install; npm start" -ForegroundColor Yellow
Write-Host "И в другом окне: cd client; npm install; npm start" -ForegroundColor Yellow