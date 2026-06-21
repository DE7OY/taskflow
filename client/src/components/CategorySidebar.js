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
    sidebar: {
      position: 'fixed',
      top: 0,
      left: 0,
      bottom: 0,
      width: '240px',
      background: '#1e1e1e',
      padding: '24px 16px',
      boxShadow: '2px 0 8px rgba(0,0,0,0.6)',
      display: 'flex',
      flexDirection: 'column',
    },
    logo: {
      fontSize: '26px',
      fontWeight: 'bold',
      color: '#90caf9',
      marginBottom: '24px',
    },
    nav: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      gap: '4px',
    },
    navItem: {
      padding: '10px 14px',
      borderRadius: '8px',
      cursor: 'pointer',
      fontSize: '16px',
      transition: 'background 0.2s',
      color: '#e0e0e0',
    },
    active: {
      background: '#2a2a4a',
      fontWeight: '500',
      color: '#90caf9',
    },
    addCategory: {
      marginTop: '16px',
      borderTop: '1px solid #333',
      paddingTop: '16px',
    },
    addBtn: {
      background: 'transparent',
      border: 'none',
      color: '#90caf9',
      fontSize: '15px',
      cursor: 'pointer',
      padding: '6px 0',
    },
    inputGroup: {
      display: 'flex',
      gap: '6px',
      alignItems: 'center',
    },
    input: {
      flex: 1,
      padding: '6px 10px',
      borderRadius: '6px',
      border: '1px solid #444',
      background: '#2d2d2d',
      color: '#e0e0e0',
      fontSize: '14px',
    },
    saveBtn: {
      padding: '6px 12px',
      background: '#90caf9',
      color: '#121212',
      border: 'none',
      borderRadius: '6px',
      fontSize: '14px',
      cursor: 'pointer',
    },
    cancelBtn: {
      background: 'transparent',
      border: 'none',
      fontSize: '20px',
      cursor: 'pointer',
      color: '#888',
    },
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