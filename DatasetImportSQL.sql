/*
* ���������� ������ ���������������� electronics_retail_dataset.csv �����,
* ��������� �������� ElectronicsRetail
*/

-- ��� ��������� ������ �������������� ��� ������� CSV (DT_STR),
-- ������ ������� ��������� �� ��������� ������� � varchar/nvarchar
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

-- ��������� ������ �� ��������� �������
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

-- ������� ��������� ����������� ��� ������ �������
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

-- ��������� �������������� ���� �� [DateRequest] (�������� �� ������������)
ALTER TABLE [dbo].[ElectronicsRetail]
ADD CONSTRAINT [AK_ElectronicsRetail_DateRequest] UNIQUE NONCLUSTERED ([DateRequest] ASC);
GO

-- ������� ������ �� [CustomerRegion] ��� ��������� ������ ��������
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_CustomerRegion]
ON [dbo].[ElectronicsRetail]([CustomerRegion] ASC);
GO

-- ������� ������ �� [ProductCategory] ��� ��������� ������ ��������
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_ProductCategory]
ON [dbo].[ElectronicsRetail]([ProductCategory] ASC);
GO

-- ��������� �������� �� ��������� ��� [Brand]
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [DF_ElectronicsRetail_Brand] DEFAULT ('Unknown') FOR [Brand];
GO

-- ��������� ����������� �� ���������� ������������� �������� � �������� ��������� � ����������
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_StandardCost] CHECK ([StandardCost]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_UnitPrice] CHECK ([UnitPrice]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_QuantitySold] CHECK ([QuantitySold]>0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_DiscountPrice] CHECK ([DiscountPrice]>=0.00);
ALTER TABLE [dbo].[ElectronicsRetail] ADD CONSTRAINT [CK_ElectronicsRetail_TotalPrice] CHECK ([TotalPrice]>=0.00);
GO

-- ������� ������������� ��� ��������� ���������� �� ��������� 
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

-- ������� ������������� ��� ��������� ���������� �� �����������
CREATE OR ALTER VIEW [dbo].[vCustomerRecap]
AS
SELECT DISTINCT
    [CustomerName],
	[CustomerCity],
	[CustomerRegion]
FROM [dbo].[ElectronicsRetail];
GO

-- ��������� ������� ����� �������� � ������� ��������������� �������
SET IDENTITY_INSERT [dbo].[ElectronicsRetail] ON;
GO

-- �������� ������ � ��������� ������� � ����������
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

-- ��������� ������� ����� �������� � ������� ��������������� �������
SET IDENTITY_INSERT [dbo].[ElectronicsRetail] OFF;
GO

-- �������������� ������������� � ������������ ��������� � �������
DECLARE @maxID int;
DECLARE @sql nvarchar(200);

SELECT @maxID = MAX(OrderID) FROM [dbo].[ElectronicsRetail];
SET @sql = 'DBCC CHECKIDENT (''[dbo].[ElectronicsRetail]'', RESEED, ' + CAST(@maxID AS nvarchar) + ')';

EXEC sp_executesql @sql;
GO

-- ������� ��������� �������
DROP TABLE [dbo].[ElectronicsRetailTempImport];
GO