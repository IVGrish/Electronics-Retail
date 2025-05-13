/*
* Производим импорт сгенерированного electronics_retail_dataset.csv файла,
* фиктивной компании ElectronicsRetail
*/

-- Для избежания ошибок преобразования при импорте CSV (DT_STR),
-- данные сначала загружаем во временную таблицу с varchar/nvarchar
DROP TABLE IF EXISTS [dbo].[ElectronicsRetailTempImport];
CREATE TABLE [dbo].[ElectronicsRetailTempImport] (
	[OrderID] varchar(50),
	[Product] varchar(50),
	[ProductCategory] nvarchar(50),
	[Brand] varchar(50),
	[Description] nvarchar(100),
	[StandardCost] varchar(50),
	[UnitPrice] varchar(50),
	[DateRequest] varchar(50),
	[QuantitySold] varchar(50),
	[DiscountPrice] varchar(50),
	[TotalPrice] varchar(50),
	[CustomerName] nvarchar(100),
	[CustomerRegion] nvarchar(50),
	[CustomerCity] nvarchar(50),
	[Canceled] varchar(50),
	[Feedback] varchar(50)
);
GO

-- Вставляем данные во временную таблицу
BULK INSERT [dbo].[ElectronicsRetailTempImport]
FROM 'D:\Dataset\electronics_retail_dataset.csv'
WITH (
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- Создаем структуру необходимой для работы таблицы
DROP TABLE IF EXISTS [dbo].[ElectronicsRetail];
CREATE TABLE [dbo].[ElectronicsRetail] (
	[OrderID] int IDENTITY(1, 1) NOT NULL,
	[Product] varchar(50) NOT NULL,
	[ProductCategory] nvarchar(50) NOT NULL,
	[Brand] varchar(50) NOT NULL,
	[Description] nvarchar(100) NULL,
	[StandardCost] money NOT NULL, 
	[UnitPrice] money NOT NULL,  
	[DateRequest] datetime2 NULL, 
	[QuantitySold] int NOT NULL,
	[DiscountPrice] decimal(3, 2) NOT NULL, 
	[TotalPrice] money NOT NULL, 
	[CustomerName] nvarchar(100) NOT NULL,
	[CustomerRegion] nvarchar(50) NOT NULL,
	[CustomerCity] nvarchar(50) NOT NULL,
	[Canceled] bit NOT NULL,
	[Feedback] tinyint NULL
CONSTRAINT [PK_ElectronicsRetail_OrderID] PRIMARY KEY CLUSTERED ([OrderID] ASC)
);
GO

-- Добавляем альтернативный ключ по [DateRequest] (кандидат на уникальность)
ALTER TABLE [dbo].[ElectronicsRetail]
ADD CONSTRAINT [AK_ElectronicsRetail_DateRequest] UNIQUE NONCLUSTERED ([DateRequest] ASC);
GO

-- Создаем индекс по [CustomerRegion] для ускорения частых запросов
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_CustomerRegion]
ON [dbo].[ElectronicsRetail]([CustomerRegion] ASC);
GO

-- Создаем индекс по [ProductCategory] для ускорения частых запросов
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_ProductCategory]
ON [dbo].[ElectronicsRetail]([ProductCategory] ASC);
GO

-- Добавляем значение по умолчанию для [Brand]
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [DF_ElectronicsRetail_Brand] DEFAULT ('Unknown') FOR [Brand];
GO

-- Добавляем ограничения на отсутствие отрицательных значений в столбцах стоимости и количества
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_StandardCost] CHECK ([StandardCost]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_UnitPrice] CHECK ([UnitPrice]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_QuantitySold] CHECK ([QuantitySold]>0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_DiscountPrice] CHECK ([DiscountPrice]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_TotalPrice] CHECK ([TotalPrice]>=0.00);
GO

-- Создаем представление для просмотра информации по продуктам 
CREATE OR ALTER VIEW [dbo].[vProductRecap]
AS
SELECT DISTINCT
    [Product],
	[ProductCategory],
	[Brand],
	[Description],
	[StandardCost],
	[UnitPrice]
FROM [dbo].[ElectronicsRetail];
GO

-- Создаем представление для просмотра информации по покупателям
CREATE OR ALTER VIEW [dbo].[vCustomerRecap]
AS
SELECT DISTINCT
    [CustomerName],
	[CustomerCity],
	[CustomerRegion]
FROM [dbo].[ElectronicsRetail];
GO

-- Позволяем вставку явных значений в столбец идентификаторов таблицы
SET IDENTITY_INSERT [dbo].[ElectronicsRetail] ON;
GO

-- Копируем данные с временной таблицы в постоянную
INSERT INTO [dbo].[ElectronicsRetail] (
    [OrderID], [Product], [ProductCategory], [Brand], [Description],
    [StandardCost], [UnitPrice], [DateRequest], [QuantitySold],
    [DiscountPrice], [TotalPrice], [CustomerName], [CustomerRegion],
    [CustomerCity], [Canceled], [Feedback]
)
SELECT 
    [OrderID], [Product], [ProductCategory], [Brand], [Description],
    [StandardCost], [UnitPrice], [DateRequest], [QuantitySold],
    [DiscountPrice], [TotalPrice], [CustomerName], [CustomerRegion],
    [CustomerCity], [Canceled], [Feedback]
FROM [dbo].[ElectronicsRetailTempImport];
GO

-- Отключаем вставку явных значений в столбец идентификаторов таблицы
SET IDENTITY_INSERT [dbo].[ElectronicsRetail] OFF;
GO

-- Синхронизируем идентификатор с максимальным значением в таблице
DECLARE @maxID int;
DECLARE @sql nvarchar(200);

SELECT @maxID = MAX(OrderID) FROM [dbo].[ElectronicsRetail];
SET @sql = 'DBCC CHECKIDENT (''[dbo].[ElectronicsRetail]'', RESEED, ' + CAST(@maxID AS nvarchar) + ')';

EXEC sp_executesql @sql;
GO

-- Удаляем временную таблицу
DROP TABLE [dbo].[ElectronicsRetailTempImport];
GO