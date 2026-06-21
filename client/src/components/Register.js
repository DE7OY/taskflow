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
    container: {
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: '#121212',
    },
    card: {
      background: '#1e1e1e',
      padding: '40px 50px',
      borderRadius: '12px',
      boxShadow: '0 4px 20px rgba(0,0,0,0.8)',
      width: '100%',
      maxWidth: '420px',
    },
    logo: {
      fontSize: '32px',
      fontWeight: 'bold',
      color: '#90caf9',
      marginBottom: '8px',
      textAlign: 'center',
    },
    subtitle: {
      fontSize: '18px',
      fontWeight: '400',
      color: '#aaaaaa',
      marginBottom: '24px',
      textAlign: 'center',
    },
    field: { marginBottom: '18px' },
    input: {
      width: '100%',
      padding: '10px 14px',
      borderRadius: '6px',
      border: '1px solid #444',
      fontSize: '16px',
      marginTop: '6px',
      background: '#2d2d2d',
      color: '#e0e0e0',
    },
    button: {
      width: '100%',
      padding: '12px',
      backgroundColor: '#90caf9',
      color: '#121212',
      border: 'none',
      borderRadius: '6px',
      fontSize: '18px',
      fontWeight: '600',
    },
    error: {
      color: '#ff6b6b',
      background: '#2d1a1a',
      padding: '10px',
      borderRadius: '6px',
      marginBottom: '16px',
      textAlign: 'center',
    },
    success: {
      color: '#69db7c',
      background: '#1a2d1a',
      padding: '10px',
      borderRadius: '6px',
      marginBottom: '16px',
      textAlign: 'center',
    },
    link: {
      textAlign: 'center',
      marginTop: '18px',
      fontSize: '15px',
      color: '#aaaaaa',
    },
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.logo}>TaskFlow</h1>
        <h2 style={styles.subtitle}>Создайте аккаунт</h2>
        {error && <div style={styles.error}>{error}</div>}
        {success && <div style={styles.success}>{success}</div>}
        <form onSubmit={handleSubmit}>
          <div style={styles.field}>
            <label>Имя пользователя</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Иван"
              required
              style={styles.input}
            />
          </div>
          <div style={styles.field}>
            <label>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="user@example.com"
              required
              style={styles.input}
              autoComplete="email"
            />
          </div>
          <div style={styles.field}>
            <label>Пароль</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="********"
              required
              style={styles.input}
              autoComplete="new-password"
            />
          </div>
          <button type="submit" style={styles.button}>Зарегистрироваться</button>
        </form>
        <p style={styles.link}>
          Уже есть аккаунт? <Link to="/login">Войти</Link>
        </p>
      </div>
    </div>
  );
}
export default Register;