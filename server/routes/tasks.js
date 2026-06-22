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
