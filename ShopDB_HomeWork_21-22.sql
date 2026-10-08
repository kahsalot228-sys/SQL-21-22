-- =============================================
-- Домашнее задание к урокам 21-22
-- База данных: ShopDB
-- Источник данных: AdventureWorks2019
-- =============================================

USE master;
GO

-- =============================================
-- 1. Создание базы данных ShopDB с файловыми группами
-- =============================================

-- Удаляем базу, если она уже существует, для чистоты эксперимента
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ShopDB')
BEGIN
    ALTER DATABASE ShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ShopDB;
END
GO

-- Создаем базу данных ShopDB
CREATE DATABASE ShopDB;
GO

-- Добавляем две новые файловые группы
ALTER DATABASE ShopDB ADD FILEGROUP ShopDB_FG1;
GO

ALTER DATABASE ShopDB ADD FILEGROUP ShopDB_FG2;
GO

-- Добавляем файлы в новые файловые группы
-- (Убедитесь, что папка C:\SQLData существует, или измените путь)
ALTER DATABASE ShopDB 
ADD FILE 
(
    NAME = 'ShopDB_Data1',
    FILENAME = 'C:\SQLData\ShopDB_Data1.ndf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP ShopDB_FG1;
GO

ALTER DATABASE ShopDB 
ADD FILE 
(
    NAME = 'ShopDB_Data2',
    FILENAME = 'C:\SQLData\ShopDB_Data2.ndf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP ShopDB_FG2;
GO

USE ShopDB;
GO

-- =============================================
-- 2. Требование: в файлах группы PRIMARY не должно быть созданных таблиц.
-- Создадим таблицы сразу в новых файловых группах, чтобы это условие выполнялось.
-- =============================================

-- =============================================
-- 3. Создание 6 таблиц (минимум 7 столбцов) и копирование данных из AdventureWorks2019
-- =============================================

-- Таблица 1: Категории продуктов (из Production.ProductCategory)
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL,
    CreatedBy NVARCHAR(50) DEFAULT 'System',
    IsActive BIT DEFAULT 1,
    Notes NVARCHAR(200) NULL
) ON ShopDB_FG1; -- Размещаем в первой файловой группе
GO

-- Таблица 2: Подкатегории продуктов (из Production.ProductSubcategory)
CREATE TABLE Subcategories (
    SubcategoryID INT PRIMARY KEY,
    SubcategoryName NVARCHAR(50) NOT NULL,
    CategoryID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL,
    CreatedBy NVARCHAR(50) DEFAULT 'System',
    Priority INT DEFAULT 0,
    Notes NVARCHAR(200) NULL
) ON ShopDB_FG1;
GO

-- Таблица 3: Продукты (из Production.Product)
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(50) NOT NULL,
    ProductNumber NVARCHAR(25) NOT NULL,
    Color NVARCHAR(15) NULL,
    ListPrice MONEY NOT NULL,
    Size NVARCHAR(5) NULL,
    Weight DECIMAL(8,2) NULL,
    ModifiedDate DATETIME NOT NULL
) ON ShopDB_FG2; -- Размещаем во второй файловой группе
GO

-- Таблица 4: Клиенты (из Sales.Customer)
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    PersonID INT NULL,
    StoreID INT NULL,
    TerritoryID INT NULL,
    AccountNumber NVARCHAR(15) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL,
    CreatedBy NVARCHAR(50) DEFAULT 'System'
) ON ShopDB_FG2;
GO

-- Таблица 5: Продавцы (из Sales.SalesPerson)
CREATE TABLE SalesPersons (
    BusinessEntityID INT PRIMARY KEY,
    TerritoryID INT NULL,
    SalesQuota MONEY NULL,
    Bonus MONEY NOT NULL,
    CommissionPct DECIMAL(5,4) NOT NULL,
    SalesYTD MONEY NOT NULL,
    SalesLastYear MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL
) ON ShopDB_FG1;
GO

-- Таблица 6: Заказы (из Sales.SalesOrderHeader)
CREATE TABLE SalesOrders (
    SalesOrderID INT PRIMARY KEY,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NULL,
    Status TINYINT NOT NULL,
    OnlineOrderFlag BIT NOT NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    TotalDue MONEY NOT NULL
) ON ShopDB_FG2;
GO

-- =============================================
-- 4. Копирование данных из AdventureWorks2019
-- Примечание: Используем TOP(1000) или другие ограничения, чтобы не перегружать учебную базу
-- =============================================

-- Копирование Категорий
INSERT INTO ShopDB.dbo.Categories (CategoryID, CategoryName, ModifiedDate, RowGuid)
SELECT TOP 10 ProductCategoryID, Name, ModifiedDate, rowguid
FROM AdventureWorks2019.Production.ProductCategory;
GO

-- Копирование Подкатегорий
INSERT INTO ShopDB.dbo.Subcategories (SubcategoryID, SubcategoryName, CategoryID, ModifiedDate, RowGuid)
SELECT TOP 20 ProductSubcategoryID, Name, ProductCategoryID, ModifiedDate, rowguid
FROM AdventureWorks2019.Production.ProductSubcategory;
GO

-- Копирование Продуктов
INSERT INTO ShopDB.dbo.Products (ProductID, ProductName, ProductNumber, Color, ListPrice, Size, Weight, ModifiedDate)
SELECT TOP 50 ProductID, Name, ProductNumber, Color, ListPrice, Size, Weight, ModifiedDate
FROM AdventureWorks2019.Production.Product;
GO

-- Копирование Клиентов
INSERT INTO ShopDB.dbo.Customers (CustomerID, PersonID, StoreID, TerritoryID, AccountNumber, ModifiedDate, RowGuid)
SELECT TOP 50 CustomerID, PersonID, StoreID, TerritoryID, AccountNumber, ModifiedDate, rowguid
FROM AdventureWorks2019.Sales.Customer;
GO

-- Копирование Продавцов
INSERT INTO ShopDB.dbo.SalesPersons (BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear, ModifiedDate)
SELECT TOP 10 BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear, ModifiedDate
FROM AdventureWorks2019.Sales.SalesPerson;
GO

-- Копирование Заказов
INSERT INTO ShopDB.dbo.SalesOrders (SalesOrderID, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, CustomerID, SalesPersonID, TotalDue)
SELECT TOP 50 SalesOrderID, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, CustomerID, SalesPersonID, TotalDue
FROM AdventureWorks2019.Sales.SalesOrderHeader;
GO

-- =============================================
-- 5. Проверка результатов (SELECT)
-- =============================================

-- Проверяем, что все таблицы созданы в нужных файловых группах
SELECT 
    t.name AS TableName,
    fg.name AS FileGroupName
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE t.name IN ('Categories', 'Subcategories', 'Products', 'Customers', 'SalesPersons', 'SalesOrders');
GO

-- Проверяем количество скопированных строк
SELECT 'Categories' AS TableName, COUNT(*) AS RowCount FROM Categories
UNION ALL
SELECT 'Subcategories', COUNT(*) FROM Subcategories
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'SalesPersons', COUNT(*) FROM SalesPersons
UNION ALL
SELECT 'SalesOrders', COUNT(*) FROM SalesOrders;
GO

-- Просмотр примеров данных
SELECT TOP 5 * FROM Products;
SELECT TOP 5 * FROM SalesOrders;
GO