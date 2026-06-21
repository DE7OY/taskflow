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
