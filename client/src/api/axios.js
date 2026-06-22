import axios from 'axios';

const api = axios.create({
  baseURL: 'https://taskflow-3zc0.onrender.com/api',  // ← обязательно /api в конце!
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

export default api;