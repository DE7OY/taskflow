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
    overlay: {
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      background: 'rgba(0,0,0,0.7)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000,
    },
    modal: {
      background: '#1e1e1e',
      padding: '32px',
      borderRadius: '12px',
      width: '100%',
      maxWidth: '520px',
      boxShadow: '0 8px 30px rgba(0,0,0,0.8)',
    },
    title: {
      fontSize: '24px',
      fontWeight: '600',
      marginBottom: '20px',
      color: '#e0e0e0',
    },
    field: {
      marginBottom: '16px',
      color: '#e0e0e0',
    },
    input: {
      width: '100%',
      padding: '10px 14px',
      borderRadius: '6px',
      border: '1px solid #444',
      fontSize: '15px',
      marginTop: '4px',
      background: '#2d2d2d',
      color: '#e0e0e0',
    },
    select: {
      width: '100%',
      padding: '10px 14px',
      borderRadius: '6px',
      border: '1px solid #444',
      fontSize: '15px',
      marginTop: '4px',
      background: '#2d2d2d',
      color: '#e0e0e0',
    },
    row: {
      display: 'flex',
      gap: '16px',
    },
    actions: {
      display: 'flex',
      justifyContent: 'flex-end',
      gap: '12px',
      marginTop: '20px',
    },
    cancelBtn: {
      padding: '10px 20px',
      border: '1px solid #444',
      borderRadius: '6px',
      background: 'transparent',
      fontSize: '16px',
      cursor: 'pointer',
      color: '#e0e0e0',
    },
    submitBtn: {
      padding: '10px 24px',
      border: 'none',
      borderRadius: '6px',
      backgroundColor: '#90caf9',
      color: '#121212',
      fontSize: '16px',
      fontWeight: '500',
      cursor: 'pointer',
    },
    error: {
      color: '#ff6b6b',
      background: '#2d1a1a',
      padding: '8px 12px',
      borderRadius: '6px',
      marginBottom: '16px',
    },
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.modal}>
        <h2 style={styles.title}>{task ? 'Редактировать задачу' : 'Новая задача'}</h2>
        {error && <div style={styles.error}>{error}</div>}
        <form onSubmit={handleSubmit}>
          <div style={styles.field}>
            <label>Название</label>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Введите название" required style={styles.input} />
          </div>
          <div style={styles.field}>
            <label>Описание</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Описание задачи..." rows="3" style={{ ...styles.input, resize: 'vertical' }} />
          </div>
          <div style={styles.row}>
            <div style={styles.field}>
              <label>Приоритет</label>
              <select value={priority} onChange={(e) => setPriority(e.target.value)} style={styles.select}>
                <option value="низкий">Низкий</option>
                <option value="средний">Средний</option>
                <option value="высокий">Высокий</option>
              </select>
            </div>
            <div style={styles.field}>
              <label>Категория</label>
              <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} style={styles.select}>
                <option value="">Без категории</option>
                {categories.map(cat => <option key={cat.id} value={cat.id}>{cat.name}</option>)}
              </select>
            </div>
          </div>
          <div style={styles.field}>
            <label>Срок выполнения</label>
            <input type="date" value={deadline} onChange={(e) => setDeadline(e.target.value)} style={styles.input} />
          </div>
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