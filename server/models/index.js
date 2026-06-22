const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: './database.sqlite',
  logging: false,
});

const User = require('./User')(sequelize, DataTypes);
const Task = require('./Task')(sequelize, DataTypes);
const Category = require('./Category')(sequelize, DataTypes);

// Определение связей
User.hasMany(Task, { foreignKey: 'userId', onDelete: 'CASCADE' });
Task.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Category, { foreignKey: 'userId', onDelete: 'CASCADE' });
Category.belongsTo(User, { foreignKey: 'userId' });

Category.hasMany(Task, { foreignKey: 'categoryId', onDelete: 'SET NULL' });
Task.belongsTo(Category, { foreignKey: 'categoryId' });

module.exports = {
  sequelize,
  User,
  Task,
  Category,
};