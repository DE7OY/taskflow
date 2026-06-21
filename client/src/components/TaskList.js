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
      case 'высокий': return { background: '#6d2a2a', color: '#ff8a80' };
      case 'средний': return { background: '#5d4a1a', color: '#ffd54f' };
      case 'низкий': return { background: '#1a4a2a', color: '#81c784' };
      default: return {};
    }
  };
  const getStatusStyle = (s) => {
    switch (s) {
      case 'выполнена': return { background: '#1a4a2a', color: '#81c784' };
      case 'в процессе': return { background: '#1a3a5a', color: '#64b5f6' };
      default: return { background: '#3a3a3a', color: '#b0b0b0' };
    }
  };

  const styles = {
    container: {
      display: 'flex',
      minHeight: '100vh',
      background: '#121212',
    },
    main: {
      flex: 1,
      padding: '24px 32px',
      marginLeft: '240px',
    },
    header: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: '20px',
    },
    title: {
      fontSize: '28px',
      fontWeight: '600',
      color: '#e0e0e0',
    },
    headerRight: {
      display: 'flex',
      alignItems: 'center',
      gap: '16px',
    },
    userInfo: {
      fontSize: '16px',
      color: '#aaaaaa',
    },
    logoutBtn: {
      padding: '6px 14px',
      border: '1px solid #444',
      borderRadius: '6px',
      background: 'transparent',
      fontSize: '14px',
      color: '#e0e0e0',
    },
    newTaskBtn: {
      padding: '8px 18px',
      backgroundColor: '#90caf9',
      color: '#121212',
      border: 'none',
      borderRadius: '6px',
      fontSize: '16px',
      fontWeight: '500',
    },
    filters: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: '16px',
      marginBottom: '24px',
      padding: '16px',
      background: '#1e1e1e',
      borderRadius: '10px',
      boxShadow: '0 1px 4px rgba(0,0,0,0.6)',
    },
    filterGroup: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      color: '#e0e0e0',
    },
    select: {
      padding: '6px 12px',
      borderRadius: '6px',
      border: '1px solid #444',
      background: '#2d2d2d',
      color: '#e0e0e0',
      fontSize: '14px',
    },
    taskGrid: {
      display: 'flex',
      flexDirection: 'column',
      gap: '16px',
    },
    taskCard: {
      background: '#1e1e1e',
      padding: '18px 20px',
      borderRadius: '10px',
      boxShadow: '0 1px 4px rgba(0,0,0,0.6)',
      borderLeft: '4px solid #90caf9',
    },
    cardHeader: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
    },
    taskTitle: {
      fontSize: '18px',
      fontWeight: '500',
      margin: 0,
      color: '#e0e0e0',
    },
    cardActions: {
      display: 'flex',
      gap: '8px',
    },
    iconBtn: {
      background: 'transparent',
      border: 'none',
      fontSize: '18px',
      padding: '4px',
      color: '#b0b0b0',
    },
    taskDesc: {
      marginTop: '6px',
      color: '#b0b0b0',
      fontSize: '14px',
    },
    taskMeta: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: '10px',
      marginTop: '12px',
      alignItems: 'center',
    },
    badge: {
      padding: '4px 12px',
      borderRadius: '20px',
      fontSize: '13px',
      fontWeight: '500',
    },
    deadline: {
      fontSize: '14px',
      color: '#aaaaaa',
    },
    category: {
      fontSize: '14px',
      background: '#2a2a4a',
      padding: '2px 12px',
      borderRadius: '20px',
      color: '#90caf9',
    },
    statusToggle: {
      display: 'flex',
      gap: '6px',
      marginTop: '12px',
    },
    activeStatus: {
      padding: '4px 12px',
      borderRadius: '20px',
      border: '1px solid #90caf9',
      background: '#90caf9',
      color: '#121212',
      fontSize: '13px',
    },
    inactiveStatus: {
      padding: '4px 12px',
      borderRadius: '20px',
      border: '1px solid #444',
      background: 'transparent',
      color: '#b0b0b0',
      fontSize: '13px',
    },
    loading: {
      textAlign: 'center',
      padding: '40px',
      color: '#aaaaaa',
    },
    empty: {
      textAlign: 'center',
      padding: '40px',
      color: '#777777',
      fontSize: '18px',
    },
  };

  return (
    <div style={styles.container}>
      <CategorySidebar
        categories={categories}
        selectedCategoryId={filters.categoryId}
        onSelectCategory={(id) => setFilters({ ...filters, categoryId: id || '' })}
        onCategoryAdded={fetchData}
      />
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
          <div style={styles.filterGroup}>
            <label>Статус:</label>
            <select value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })} style={styles.select}>
              <option value="">Все</option>
              {statuses.map(s => <option key={s} value={s}>{s === 'новая' ? 'Новые' : s === 'в процессе' ? 'В процессе' : 'Выполнено'}</option>)}
            </select>
          </div>
          <div style={styles.filterGroup}>
            <label>Приоритет:</label>
            <select value={filters.priority} onChange={(e) => setFilters({ ...filters, priority: e.target.value })} style={styles.select}>
              <option value="">Все</option>
              {priorities.map(p => <option key={p} value={p}>{p.charAt(0).toUpperCase() + p.slice(1)}</option>)}
            </select>
          </div>
          <div style={styles.filterGroup}>
            <label>Сортировка:</label>
            <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} style={styles.select}>
              <option value="createdAt">По дате создания</option>
              <option value="deadline">По дедлайну</option>
              <option value="priority">По приоритету</option>
            </select>
            <select value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} style={{ ...styles.select, width: '80px' }}>
              <option value="desc">↓</option>
              <option value="asc">↑</option>
            </select>
          </div>
        </div>
        {loading ? <div style={styles.loading}>Загрузка...</div> : (
          <div style={styles.taskGrid}>
            {tasks.length === 0 ? <div style={styles.empty}>Нет задач. Создайте первую!</div> : tasks.map(task => (
              <div key={task.id} style={styles.taskCard}>
                <div style={styles.cardHeader}>
                  <h3 style={styles.taskTitle}>{task.title}</h3>
                  <div style={styles.cardActions}>
                    <button onClick={() => handleEdit(task)} style={styles.iconBtn}>✏️</button>
                    <button onClick={() => handleDelete(task.id)} style={styles.iconBtn}>🗑️</button>
                  </div>
                </div>
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