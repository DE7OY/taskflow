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
